use Data::Dumper;
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
my $trainingFile = @ARGV[0];
my $testFile = @ARGV[1];

#My two hash tables I use to generate n-gram tokens.  Its easier and faster to just have a completely different structure
#for a unigram model, so it has its own, separate hash structure.
my $n = 2;
my %hash            = ();
my %hash2            = ();
my %fallback        = ();
my @arrayHold       = ();
my @array     = ();
my @history   = ();
my $prevTags;
my $uncertainty = 0;


#If any command line arguments are missing program will exit and provide an error.
if ( not defined $trainingFile ) {
    die "Need a text file for training.\n";
}

if ( not defined $testFile ) {
    die "Need a text file to test.\n";
}

#Break if file not found.
open( SRC, $trainingFile )
    or die "Could not open file $!";

while ( $line = <SRC> ) {
    chomp;

    $line =~ s/\[ //g;
    $line =~ s/ \]//g;
    $line =~ s/^\s+//;

    for ( my $i = ($n) ; $i > 0 ; $i-- ) {
        if (@arrayHold[ -$i ] ne '') {
            push @array, @arrayHold[ -$i ];
        }
    }

    @array2 = split( /\s/, $line );
    push @array, @array2;

    for my $i ( 0 .. $#array ) {
        if ( $array[$i] eq "" ) {
            splice @array, $i, 1;
        }
    }

    @arrayHold = @array;

    for ( my $i = 0 ; $i <= $#array - $n ; $i++ ) {
        my $j     = $i + $n - 1;
        my $first = "";
        my $followed = "";
        my $hold = "";
        if ( $j > $#array ) {
            next;
        }
        for my $k ( $i .. $j ) {
            if ( $k < $j ) {
                $hold = $array[$k];
                $hold =~ s/[^\/]*\///g;
                $first .= $hold;
            }
            else {
                $followed .= $array[$k];
            }
        }

        $word_pos = $followed;
        $pos = $word_pos;
        $pos =~ s/[^\/]*\///g;
        $followed =~ s/\/.*//g;

        $hash{$first}{$followed}{$word_pos}++;
        if ( $hash{$first}{$followed}{$word_pos} > $hash{$first}{$followed}{'cmeCount'}
        || $hash{$first}{$followed}{'cmeCount'} eq undef) {
            $hash{$first}{$followed}{'cmeCount'} = $hash{$first}{$followed}{$word_pos};
            $hash{$first}{$followed}{'cme'} = $pos;
        }

        $fallback{$followed}{$pos}++;
        if ( $fallback{$followed}{$pos} > $fallback{$followed}{'cmeCount'}
        || $fallback{$followed}{'cmeCount'} eq undef) {
            $fallback{$followed}{'cmeCount'} = $fallback{$followed}{$pos};
            $fallback{$followed}{'cme'} = $pos;
        }

        $hashRand{$first}{$followed}{'_total'}++;
        $hashRand{$first}{$followed}{ $hashRand{$first}{'_total'} } = $pos;
    }
    @array = ();
}


#Break if file not found.
open( SRC, $testFile )
    or die "Could not open file $!";

while ( $line = <SRC> ) {
    chomp;
    $line =~ s/^\s+|\s+$//g ;
    @array = split( /\s+/, $line );

    for ( my $i = 0 ; $i <= $#array; $i++ ) {
        if ( $array[$i] eq "") {
            splice @array, $i, 1;
        }
        elsif ($array[$i] ne "[" && $array[$i] ne "]") {
            $currWord = $array[$i];
            GetHistory();
            $array[$i] = TagWord($currWord);
        }
    }
    ConstructLine(@array);
    @array = ();
}

#The algorithm that generates the next word of the n-gram for any n > 1.
sub TagWord($currWord) {
    my $tag;

    if ($currWord eq '') {
        return "NOT A WORD";
    }

    $tag = $hash{$prevTags}{$currWord}{'cme'};

    if ($tag eq "") {
        $tag = $fallback{$currWord}{'cme'};
    }

    if ($tag eq "") {
        if ($currWord =~ /^[A-Z]/) {
            $tag = "NNP";
        }
        elsif ($currWord =~ /ing$/) {
            $tag = "VBG";
        }
        elsif ($currWord =~ /ed$/) {
            $tag = "VBN";
        }
        elsif ($currWord =~ /en$/) {
            $tag = "VBN";
        }
        elsif ($currWord =~ /s$/ && !($currWord =~ /^[A-Z]/)) {
            $tag = "NNS";
        }
        elsif ($currWord =~ /er$/) {
            $tag = "JJR";
        }
        elsif ($currWord =~ /ly$/) {
            $tag = "RB";
        }
        elsif ($currWord =~ /[0-9]/) {
            $tag = "CD";
        }
        else {
            $tag = "NN";
        }
        $uncertainty = 1;
    }

    if (($currWord =~ /^[A-Z]/) && ($tag eq "NNPS") && 
        !($currWord =~ /a?ns?$/ || $currWord =~ /ians?$/ || $currWord =~ /anians?$/ || 
        $currWord =~ /nias?n$/ || $currWord =~ /ine?s?$/ || $currWord =~ /ites?$/ || 
        $currWord =~ /ans?$/ || $currWord =~ /ers?$/ || $currWord =~ /ish$/ || 
        $currWord =~ /(ese|lese|vese|nese)$/ || $currWord =~ /ie?$/ || $currWord =~ /ic$/ || 
        $currWord =~ /iote?$/ || $currWord =~ /asque$/ || $currWord =~ /(we)?gian$/ || 
        $currWord =~ /onian$/ || $currWord =~ /vian$/ || $currWord =~ /san$/ || 
        $currWord =~ /(oise?|aise?)$/)) {
        $tag = "NNP";
    }

    push @history, $tag;
    $taggedWord = $currWord."/".$tag;
    return $taggedWord;
}

sub ConstructLine() {
    my $line;
    for ( my $i = 0 ; $i <= $#array; $i++ ) {
        $line .= $array[$i] . " ";
    }
    print $line."\n";
}

sub GetHistory() {
    $prevTags = $history[-1];
}

# sub TagRandom($currWord) {
#     my $count     = $hash{$prevTags}{$currWord}{'_total'};
#     my $intRandom = int( rand( $count - 1 ) );
#     my $tag      = $hash{$prevTags}{$currWord}{ $intRandom + 1 };
#     push @history, $tag;
#     $taggedWord = $currWord."/".$tag;
#     return $taggedWord;
# }



