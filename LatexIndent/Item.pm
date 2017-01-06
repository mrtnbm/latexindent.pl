# Items.pm
#   creates a class for the Item object
#   which are a subclass of the Document object.
package LatexIndent::Item;
use strict;
use warnings;
use LatexIndent::Tokens qw/%tokens/;
use LatexIndent::TrailingComments qw/$trailingCommentRegExp/;
use LatexIndent::GetYamlSettings qw/%masterSettings/;
use Data::Dumper;
use Exporter qw/import/;
our @ISA = "LatexIndent::Document"; # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/find_items construct_list_of_items/;
our $itemCounter;
our $listOfItems = q();
our $itemRegExp; 

sub construct_list_of_items{
    my $self = shift;

    # put together a list of the items
    while( my ($item,$lookForThisItem)= each %{$masterSettings{itemNames}}){
        $listOfItems .= ($listOfItems eq "")?"$item":"|$item" if($lookForThisItem);
    }

    # detail items in the log
    $self->logger("List of items: $listOfItems (see itemNames)",'heading');

    $itemRegExp = qr/
                          (
                              \\($listOfItems)
                              \h*
                              (\R*)?
                          )
                          (
                              (?:                 # cluster-only (), don't capture 
                                  (?!             
                                      (?:\\(?:$listOfItems)) # cluster-only (), don't capture
                                  ).              # any character, but not \\$item
                              )*                 
                          )                       
                          (\R)?
                       /sx;
    

    return;
}

sub find_items{
    # no point carrying on if the list of items is empty
    return if($listOfItems eq "");

    my $self = shift;

    return unless ${$masterSettings{indentAfterItems}}{${$self}{name}};

    # otherwise loop through the item names
    $self->logger("Searching for items (see itemNames) in ${$self}{name} (see indentAfterItems)");
    $self->logger(Dumper(\%{$masterSettings{itemNames}}));

    while(${$self}{body} =~ m/$itemRegExp\h*($trailingCommentRegExp)?/){

        # log file output
        $self->logger("Item found: $2",'heading');

        # create a new Item object
        my $itemObject = LatexIndent::Item->new(begin=>$1,
                                                body=>$4,
                                                end=>q(),
                                                name=>$2,
                                                linebreaksAtEnd=>{
                                                  begin=>$3?1:0,
                                                  body=>$5?1:0,
                                                },
                                                aliases=>{
                                                  # begin statements
                                                  BeginStartsOnOwnLine=>"ItemStartsOnOwnLine",
                                                  # body statements
                                                  BodyStartsOnOwnLine=>"ItemFinishesWithLineBreak",
                                                },
                                                modifyLineBreaksYamlName=>"items",
                                                regexp=>$itemRegExp,
                                                endImmediatelyFollowedByComment=>$5?0:($6?1:0),
                                              );

        # the item body could hoover up line breaks; we do an additional check
        ${${$itemObject}{linebreaksAtEnd}}{body}=1 if(${$itemObject}{body} =~ m/\R+$/s );

        # the settings and storage of most objects has a lot in common
        $self->get_settings_and_store_new_object($itemObject);
    }
}


sub create_unique_id{
    my $self = shift;

    $itemCounter++;

    ${$self}{id} = "$tokens{item}$itemCounter";
    return;
}

sub tasks_particular_to_each_object{
    my $self = shift;

    # search for ifElseFi blocks
    $self->logger('looking for IFELSEFI');
    $self->find_ifelsefi;

    # search for headings (part, chapter, section, setc)
    $self->logger('looking for HEADINGS (chapter, section, part, etc)');
    $self->find_heading;
    
    # search for commands with arguments
    $self->logger('looking for COMMANDS and key = {value}');
    $self->find_commands_or_key_equals_values_braces;

    # search for special begin/end
    $self->logger('looking for SPECIAL begin/end');
    $self->find_special;

}
1;
