# IfElseFi.pm
#   creates a class for the IfElseFi objects
#   which are a subclass of the Document object.
package LatexIndent::IfElseFi;
use strict;
use warnings;
use LatexIndent::Tokens qw/%tokens/;
use LatexIndent::TrailingComments qw/$trailingCommentRegExp/;
use Data::Dumper;
use Exporter qw/import/;
our @ISA = "LatexIndent::Document"; # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/find_ifelsefi/;
our %previouslyFoundSettings;
our $ifElseFiCounter;

sub indent{
    my $self = shift;

    # determine the surrounding and current indentation
    $self->determine_total_indentation;

    # indent the body
    $self->indent_body;

    # calculate and grab the surrounding indentation for the \else statement adjustment
    $self->get_surrounding_indentation;
    my $surroundingIndentation = ${$self}{surroundingIndentation}?${$self}{surroundingIndentation}:q();

    if(${$self}{elsePresent} and ${$self}{linebreaksAtEnd}{ifbody}){
            $self->logger("Adding surrounding indentation to \\else statement ('$surroundingIndentation')");
            ${$self}{body} =~ s/\h*\\else/$surroundingIndentation\\else/; 
            $self->logger("Body (${$self}{name}) after \\else adjustment:\n${$self}{body}","trace");
    }

    # indent the end statement
    $self->indent_end_statement;

    # wrap-up statement
    $self->wrap_up_statement;

    # line break checks *after* \end{statement}
    if (defined ${$self}{EndFinishesWithLineBreak}
        and ${$self}{EndFinishesWithLineBreak}==0 
        ) {
        # add a single horizontal space after the child id, otherwise we can end up 
        # with things like
        #       before: 
        #               \fi
        #                   text
        #       after:
        #               \fitext
        $self->logger("Adding a single space after \\fi statement (otherwise \\fi can be comined with next line of text in an unwanted way)",'heading.trace');
        ${$self}{end} =${$self}{end}." ";
    }

    return $self;
}

sub find_ifelsefi{
    my $self = shift;

    # store the regular expresssion for matching and replacing the \if...\else...\fi statements
    # note: we search for \else separately in an attempt to keep this regexp a little more managable
    my $ifElseFiRegExp = qr/
                    (
                        \\
                            (@?if[a-zA-Z@]*?)
                        \h*
                        (\R*)
                    )                           # begin statement, e.g \ifnum, \ifodd
                    (
                        \\(?!if)|\R|\h|\#|!-!   # up until a \\, linebreak # or !-!, which is 
                    )                           # part of the tokens used for latexindent
                    (
                        (?: 
                            (?!\\if).
                        )*?                     # body, which can't include another \if
                    )
                    (\R*)                       # linebreaks after body
                    (
                        \\fi                    # \fi statement 
                        \h*                     # 0 or more horizontal spaces
                    )
                    (\R)?                       # linebreaks after \fi
    /sx;

    while( ${$self}{body} =~ m/$ifElseFiRegExp\h*($trailingCommentRegExp)?/){
      # log file output
      $self->logger("IfElseFi found: $2",'heading');

      # create a new IfElseFi object
      my $ifElseFi = LatexIndent::IfElseFi->new(begin=>$1.(($4 eq "\n" and !$3)?"\n":q()),
                                              name=>$2,
                                              # if $4 is a line break, don't count it twice (it will already be in 'begin')
                                              body=>($4 eq "\n") ? $5.$6 : $4.$5.$6,
                                              end=>$7,
                                              linebreaksAtEnd=>{
                                                begin=>(($4 eq "\n")||$3)?1:0,
                                                body=>$6?1:0,
                                                end=>$8?1:0,
                                              },
                                              aliases=>{
                                                # begin statements
                                                BeginStartsOnOwnLine=>"IfStartsOnOwnLine",
                                                # end statements
                                                EndStartsOnOwnLine=>"FiStartsOnOwnLine",
                                                # after end statements
                                                EndFinishesWithLineBreak=>"FiFinishesWithLineBreak",
                                              },
                                              elsePresent=>0,
                                              modifyLineBreaksYamlName=>"ifElseFi",
                                              additionalAssignments=>["ElseStartsOnOwnLine","ElseFinishesWithLineBreak"],
                                              regexp=>$ifElseFiRegExp,
                                              endImmediatelyFollowedByComment=>$8?0:($9?1:0),
                                            );

      # the settings and storage of most objects has a lot in common
      $self->get_settings_and_store_new_object($ifElseFi);
    } 
    return;
}

sub tasks_particular_to_each_object{
    my $self = shift;

    # check for existence of \else statement, and associated line break information
    $self->check_for_else_statement;

}

sub create_unique_id{
    my $self = shift;

    $ifElseFiCounter++;

    ${$self}{id} = "$tokens{ifelsefi}$ifElseFiCounter";
    return;
}

sub check_for_else_statement{
    my $self = shift;
    $self->logger("Looking for \\else statement (${$self}{name})",'heading.trace');
    if(${$self}{body} =~ m/
                            (\R*)   # possible line breaks before \else statement
                            \\else  
                            \h*     # possible horizontal space
                            (\R*)   # possible line breaks after \else statement
                            /x){
      $self->logger("found \\else statement, storing line break information:",'trace') if($self->is_t_switch_active);

      # linebreaks *before* \else statement
      ${$self}{linebreaksAtEnd}{ifbody} = $1?1:0;
      $self->logger("linebreaksAtEnd of ifbody: ${$self}{linebreaksAtEnd}{ifbody}",'trace') if($self->is_t_switch_active);

      # linebreaks *after* \else statement
      ${$self}{linebreaksAtEnd}{else} = $2?1:0;
      $self->logger("linebreaksAtEnd of else: ${$self}{linebreaksAtEnd}{else}",'trace') if($self->is_t_switch_active);
      ${$self}{elsePresent}=1;

      # check that \else isn't the first thing in body
      if(${$self}{body} =~ m/^\\else/s and ${$self}{linebreaksAtEnd}{begin}){
        ${$self}{linebreaksAtEnd}{ifbody} = 1;
        $self->logger("\\else *begins* the ifbody, linebreaksAtEnd of ifbody: ${$self}{linebreaksAtEnd}{ifbody}",'trace') if($self->is_t_switch_active);
      }

      # check if -m switch is active
      return unless $self->is_m_switch_active;

      # possibly modify line break *before* \else statement
      if(defined ${$self}{ElseStartsOnOwnLine}){
          if(${$self}{ElseStartsOnOwnLine}==1 and !${$self}{linebreaksAtEnd}{ifbody}){
              # add a line break after ifbody, if appropriate
              $self->logger("Adding a linebreak before the \\else statement (see ElseStartsOnOwnLine)");
              ${$self}{body} =~ s/\\else/\n\\else/s;
              ${$self}{linebreaksAtEnd}{ifbody} = 1;
          } elsif (${$self}{ElseStartsOnOwnLine}==0 and ${$self}{linebreaksAtEnd}{ifbody}){
              # remove line break *after* ifbody, if appropriate
              $self->logger("Removing linebreak before \\else statement (see ElseStartsOnOwnLine)");
              ${$self}{body} =~ s/\R*(\h*)\\else/$1\\else/sx;
              ${$self}{linebreaksAtEnd}{ifbody} = 0;
          }
      }

      # possibly modify line break *before* \else statement
      if(defined ${$self}{ElseFinishesWithLineBreak}){
          if(${$self}{ElseFinishesWithLineBreak}==1 and !${$self}{linebreaksAtEnd}{else}){
              # add a line break after else, if appropriate
              $self->logger("Adding a linebreak after the \\else statement (see ElseFinishesWithLineBreak)");
              ${$self}{body} =~ s/\\else\h*/\\else\n/s;
              ${$self}{linebreaksAtEnd}{else} = 1;
          } elsif (${$self}{ElseFinishesWithLineBreak}==0 and ${$self}{linebreaksAtEnd}{else}){
              # remove line break *after* else, if appropriate, 
              # note the space so that, for example,
              #     \else
              #             some text
              # becomes
              #     \else some text
              # and not
              #     \elsesome text
              $self->logger("Removing linebreak after \\else statement (see ElseFinishesWithLineBreak)");
              ${$self}{body} =~ s/\\else\h*\R*/\\else /sx;
              ${$self}{linebreaksAtEnd}{else} = 0;
          }
      }

      return;
    } else {
      $self->logger("\\else statement not found",'trace') if($self->is_t_switch_active);
    }
}

1;
