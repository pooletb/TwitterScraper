use Data::Dumper;
use Text::SimpleTable::AutoWidth;
#Tyler Poole
#2/19/19
#INTRO TO NATURAL LANG PROCESS CMSC 416

#This is a program to designed to generate sentences based off any give n-gram model.  It takes
#three (or more) inputs to run:  an n values that is used to tokenize the given text files,
#a number of sentences to generate at the end, and any number of text files greater than zero.
#eg. to run this program you would type perl ngram.pl 3 5 text1.txt text2.txt to generate 5 sentences based
#on a trigram model built off of the text files text1.txt and text2.txt.  To accomplish the minimizing of looping
#through the hash to generate a distribution I treated the hash as a distribution itself.  Each set of n-1 previous words 
#contains a property, _total, and every time those words are seen the next word is logged under them with a key/value pair
#of the current value of _total, word.  Duplicates are allowed meaning if "ran" is seen 17 times after "The dog" in a trigram model,
#17 places between 1 and _total will represent "ran" under "The dog".  This gives a distribution without much processing power because 
#all numbers are represented completely and the percentages add up to 100% in total.

#These are all global variables to assist in the running of the program and building of the model
#These variables have to do specifically with gathering command line arguments.
my $testFile = @ARGV[0];
my $keyFile = @ARGV[1];

my %matrix = ();

my $correct;
my $incorrect;
my $total;
my $accuracy;

my @valuesHolder;

#If any command line arguments are missing program will exit and provide an error.
if ( not defined $testFile ) {
    die "Need a text file that was tagged.\n";
}

if ( not defined $keyFile ) {
    die "Need a text file to score with.\n";
}

#Break if file not found.
open( SRC1, $testFile )
    or die "Could not open file $!";

open( SRC2, $keyFile )
    or die "Could not open file $!";

while ( $lineTest = <SRC1> ) {
    $lineKey = <SRC2>;

    chomp($lineTest);
    chomp($lineKey);

    $lineTest =~ s/\[ //g;
    $lineTest =~ s/ \]//g;
    $lineTest =~ s/^\s+//;
    $lineTest =~ s/^\s+|\s+$//g ;

    $lineKey =~ s/\[ //g;
    $lineKey =~ s/ \]//g;
    $lineKey =~ s/^\s//;
    $lineKey =~ s/^\s+|\s+$//g ;


    my @arrayTest = split( /\s+/, $lineTest );
    my @arrayKey = split( /\s+/, $lineKey );

    for ( my $i = 0 ; $i <= $#arrayTest; $i++ ) {
        my $posTest = $arrayTest[$i];
        my $posKey = $arrayKey[$i];

        $posTest =~ s/[^\/]*\///g;
        $posKey =~ s/[^\/]*\///g;

        if ( $posTest eq $posKey) {
            $correct++;
            $total++;
        }
        else {
            $incorrect++;
            $total++;
        }

        $matrix{$posTest}{$posKey}++;
    }
    $accuracy = ($correct/$total) * 100;
}

# my @keys = keys %matrix;
# my $t1 = Text::SimpleTable::AutoWidth->new();
# $t1->row( 'A\\P', @keys );
# for (my $i = 0; $i <= $#keys; $i++) {
#     for (my $j = 0; $j <= $#keys; $j++) {
#         my $value = $matrix{$keys[$j]}{$keys[$i]};
#         push(@valuesHolder, $value);
#     }  
#     $t1->row( $keys[$i] , @valuesHolder);   
#     @valuesHolder = ();
# }
# print $t1->draw;
print Dumper(\%matrix);
print "\n";
print "\n";
print "\n";
print "\n";
print "\n";
print "\n";
print "\n";
print "\n";
print "\n";
print "\n";
print "Total Analyzed:  $total\n";
print "Correctly Predicted:  $correct\n";
print "Incorrectly Predicted:  $incorrect\n";
print "Accuracy:  $accuracy\n";

