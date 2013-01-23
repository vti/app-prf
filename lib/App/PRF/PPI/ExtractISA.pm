package App::PRF::PPI::ExtractISA;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub extract {
    my $self = shift;
    my ($ppi) = @_;

    my @isa;
    my $includes = $ppi->find('Statement::Include') || [];
    for my $node (@$includes) {
        next if grep { $_ eq $node->module } qw{ lib };

        if (grep { $_ eq $node->module } qw{ base parent }) {

            my @meat = grep {
                     $_->isa('PPI::Token::QuoteLike::Words')
                  || $_->isa('PPI::Token::Quote')
            } $node->arguments;

            foreach my $token (@meat) {
                if (   $token->isa('PPI::Token::QuoteLike::Words')
                    || $token->isa('PPI::Token::Number'))
                {
                    push @isa, $token->literal;
                }
                else {
                    next if $token->content =~ m/^base|parent$/;
                    push @isa, $token->string;
                }
            }
            next;
        }
    }

    return @isa;
}

1;
