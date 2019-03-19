#Tyler Poole
#2/19/19

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
my $length    = @ARGV;
my $n         = @ARGV[0];
my $sentences = @ARGV[1];
my @fileNames;

#My two hash tables I use to generate n-gram tokens.  Its easier and faster to just have a completely different structure
#for a unigram model, so it has its own, separate hash structure.
my %hash            = ();
my %unigrams        = ();

#This variable is used to store the word history for n-grams > 1.
my $prevWords       = "";
my @history         = ();

#For determining where a quote begins and ends and treating them as separate tokens.
my $quotationStatus = 0;

#The rest of these variables help to gather tokens.
my @arrayHold       = ();
my $period          = "endPd";
my $exclamation     = "endEm";
my $question        = "endQm";
my $startPd         = "";
my $startEm         = "";
my $startQm         = "";

#Sentences will be added to the paragraph array as they are generated.
my @paragraph;

#If any command line arguments are missing program will exit and provide an error.
if ( not defined $n ) {
    die "Need an n-value.\n";
}

if ( not defined $sentences ) {
    die "Need a number of sentences to produce.\n";
}

if ( not defined $ARGV[2] ) {
    die "Need at least one text file input to analyze.\n";
}

#Generating n-1 start tokens to use as the previous word at the beginning of a sentence.
for my $i ( 0 .. $n - 2 ) {
    $period      .= " startPd";
    $exclamation .= " startEm";
    $question    .= " startQm";
}

#"Zeroing" out the holder array with n spaces.  The holder array provides a rolling analysis 
#of the whole document by not throwing out the last n-1 elements of a line and rolling them into the
#beginning of the next line to help prevent stalling or crashing.
for my $i ( 0 .. $n ) {
    push @arrayHold, "";
}

#Collecting the filenames to iterate through.
for ( my $i = 2 ; $i < $length ; $i++ ) {
    push @fileNames, @ARGV[$i];
}

#The big loop that loops through each file tokenizing them.
for ( my $i = 0 ; $i <= $#fileNames ; $i++ ) {
    #Break if file not found.
    open( SRC, @fileNames[$i] )
      or die "Could not open file '@fileNames[$i]' $!";

    while ( $line = <SRC> ) {
        chomp;
        $line =~ s/\b(https\:\/\/t\.co\/[a-zA-Z0-9]*)\b//g;
        $line =~ s/\“/\"/g;
        $line =~ s/\”/\"/g;
        $line =~ s/([[:punct:]])/ $1 /g;
        $line =~ s/^\s+|\s+$//g;
        $line =~ s/\./$period/g;
        $line =~ s/\!/$exclamation/g;
        $line =~ s/\?/$question/g;

        my @array;

        for ( my $i = ($n) ; $i > 0 ; $i-- ) {
            push @array, @arrayHold[ -$i ];
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
            my $ngram = "";
            if ( $j > $#array ) {
                next;
            }
            for my $k ( $i .. $j ) {
                if ( $array[$k] eq "\"") {
                    if ( $quotationStatus == 0 ) {
                        $array[$k] = "beginQuote";
                        $quotationStatus = 1;
                    }
                    else {
                        $array[$k] = "endQuote";
                        $quotationStatus = 0;
                    }
                }

                if ( $k < $j ) {
                    $first .= $array[$k] . " ";
                }
                else {
                    $ngram .= $array[$k] . " ";
                }
                $unigrams{'_total'}++;
                $unigrams{ $unigrams{'_total'} } = $array[$k] . " ";
            }
            chomp $ngram;
            $hash{$first}{'_total'}++;
            $hash{$first}{ $hash{$first}{'_total'} } = $ngram;
        }
    }
}

#The second big loop devoted to sentence generation.  A lot of regex is used here to analyze the sentence and correct potential errors and 
#just clean it up in general.  Here I will see things like if theres a startQuote token with no endQuote and append an endQuote, replace the 
#tokens with what the represent respectively etc.  Overall it works pretty great and comes out formatted but every once in a while it will get
#caught on generating complete trash if the first word contains a bracket or something.
for my $i ( 1 .. $sentences ) {
    my $sentence     = "";
    my $sentenceHold = "";
    my $flag = 0;
    StartArray();
    if ( $n == 1 ) {
        while (42) {
            $sentence .= ContinueSentenceUni();
            if ( $sentence =~ /endPd/ || $sentence =~ /endEm/ || $sentence =~ /endQm/ ) {
                if ($sentence =~ /endPd/) {
                    $flag = 0;
                }
                elsif ($sentence =~ /endEm/) {
                    $flag = 1;
                }
                else {
                    $flag = 2;
                }
                $sentenceHold = $sentence;
                $sentenceHold =~ s/startPd//;
                $sentenceHold =~ s/endPd//;
                $sentenceHold =~ s/startEm//;
                $sentenceHold =~ s/endEm//;
                $sentenceHold =~ s/startQm//;
                $sentenceHold =~ s/endQm//;
                $sentenceHold =~ s/([[:punct:]])/ $1 /g;
                my @sentArray = split( /\s+/, $sentenceHold );
                if ( $#sentArray < 10 ) {
                    $sentence = "";
                    StartArray();
                }
                else {
                    $sentence =~ s/\s+$//;
                    $sentence =~ s/startPd//;
                    $sentence =~ s/endPd//;
                    if ( $sentence =~ /beginQuote/
                        && !( $sentence =~ /endQuote/ ) )
                    {
                        $sentence .= "\"";
                    }
                    if ( $sentence =~ /endQuote/
                        && !( $sentence =~ /beginQuote/ ) )
                    {
                        $sentence = "\"" . $sentence;
                    }
                    if ( $sentence =~ /endEm/ || $sentence =~ /endQm/ ) {
                        $sentence =~ s/endEm/!/g;
                        $sentence =~ s/endQm/?/g;
                        $sentence =~ s/startQm//g;
                        $sentence =~ s/startEm//g;
                    }
                    $sentence =~ s/beginQuote /\"/g;
                    $sentence =~ s/ endQuote/\" /g;
                    $sentence =~ s/"endQuote //g;
                    $sentenceHold = $sentence;
                    my @sentArray = split( /\s+/, $sentenceHold );
                    $sentence = "";
                    for my $i ( 0 .. $#sentArray ) {

                        if (   $sentArray[ $i + 1 ] eq "\,"
                            || $sentArray[ $i + 1 ] eq "\'"
                            || $sentArray[ $i + 1 ] eq "\;"
                            || $sentArray[ $i + 1 ] eq "\:"
                            || $sentArray[ $i + 1 ] eq "\%"
                            || $sentArray[ $i + 1 ] eq "\]"
                            || $sentArray[ $i + 1 ] eq "\)"
                            || $sentArray[ $i + 1 ] eq "\}"
                            || $sentArray[ $i + 1 ] eq "\""
                            || $sentArray[ $i + 1 ] eq "\?"
                            || $sentArray[ $i + 1 ] eq "\!" )
                        {
                            $sentence .= "$sentArray[$i]";
                        }
                        elsif (
                            $i > 0
                            && (   $sentArray[$i] eq "\,"
                                && $sentArray[ $i - 1 ] =~ /\d/
                                && $sentArray[ $i + 1 ] =~ /\d/ )
                          )
                        {
                            $sentence .= "$sentArray[$i]";
                        }
                        elsif (
                            $i > 0
                            && (   $sentArray[$i] eq "\:"
                                && $sentArray[ $i - 1 ] =~ /\d/
                                && $sentArray[ $i + 1 ] =~ /\d/ )
                          )
                        {
                            $sentence .= "$sentArray[$i]";
                        }
                        elsif ($sentArray[$i] eq "\:"
                            || $sentArray[$i] eq "\?"
                            || $sentArray[$i] eq "\!" )
                        {
                            $sentence .= "$sentArray[$i]  ";
                        }
                        elsif ($sentArray[$i] eq "\'"
                            || $sentArray[$i] eq "\@"
                            || $sentArray[$i] eq "\#"
                            || $sentArray[$i] eq "\$"
                            || $sentArray[$i] eq "\["
                            || $sentArray[$i] eq "\("
                            || $sentArray[$i] eq "\("
                            || $sentArray[$i] eq "\{" )
                        {
                            $sentence .= "$sentArray[$i]";
                        }
                        elsif ($i == $#sentArray
                            && $sentArray[$i] ne ""
                            && $sentArray[$i] ne " " )
                        {
                            $sentence .= "$sentArray[$i]";
                        }
                        elsif ( $sentArray[$i] ne "" && $sentArray[$i] ne " " )
                        {
                            $sentence .= "$sentArray[$i] ";
                        }
                    }
                    if ($flag == 0) {
                        $sentence .= ".";
                    }
                    $sentence .= "\n";
                    if (   $sentence =~ /\"\"/
                        || $sentence =~ /\" \"/
                        || $sentence =~ /\"  \"/ )
                    {
                        $sentence =~ s/\"\"//g;
                        $sentence =~ s/\" \"//g;
                        $sentence =~ s/\"  \"//g;
                        $sentence =~ s/ \"\"//g;
                        $sentence =~ s/ \" \"//g;
                        $sentence =~ s/ \"  \"//g;
                        $sentence =~ s/ \"\" / /g;
                        $sentence =~ s/ \" \" / /g;
                        $sentence =~ s/ \"  \" / /g;
                    }
                    if ( $sentence =~ /amp;/ ) {
                        $sentence =~ s/amp;//g;
                        $sentence =~ s/ amp;//g;
                        $sentence =~ s/ amp; / /g;
                    }
                    $sentence =~ s/\"\./\.\"/g;
                    $sentence =~ s/\"\!/\!\"/g;
                    $sentence =~ s/\"\?/\?\"/g;
                    $sentence =~ s/endQuote //g;
                    $sentence =~ s/beginQuote //g;
                    last;
                }
            }
        }
    }
    else {
        while (42) {
            GetPrevWords();
            $sentence .= ContinueSentence();

            if ( $sentence =~ /endPd/ || $sentence =~ /endEm/ || $sentence =~ /endQm/ ) {
                if ($sentence =~ /endPd/) {
                    $flag = 0;
                }
                elsif ($sentence =~ /endEm/) {
                    $flag = 1;
                }
                else {
                    $flag = 2;
                }
                $sentenceHold = $sentence;
                $sentenceHold =~ s/startPd//;
                $sentenceHold =~ s/endPd//;
                $sentenceHold =~ s/startEm//;
                $sentenceHold =~ s/endEm//;
                $sentenceHold =~ s/startQm//;
                $sentenceHold =~ s/endQm//;
                $sentenceHold =~ s/([[:punct:]])/ $1 /g;
                my @sentArray = split( /\s+/, $sentenceHold );
                if ( $#sentArray < 10 ) {
                    $sentence = "";
                    StartArray();
                }
                else {
                    $sentence =~ s/\s+$//;
                    $sentence =~ s/startPd//;
                    $sentence =~ s/endPd//;
                    if ( $sentence =~ /beginQuote/
                        && !( $sentence =~ /endQuote/ ) )
                    {
                        $sentence .= "\"";
                    }
                    if ( $sentence =~ /endQuote/
                        && !( $sentence =~ /beginQuote/ ) )
                    {
                        $sentence = "\"" . $sentence;
                    }
                    if ( $sentence =~ /endEm/ || $sentence =~ /endQm/ ) {
                        $sentence =~ s/endEm/!/g;
                        $sentence =~ s/endQm/?/g;
                        $sentence =~ s/startQm//g;
                        $sentence =~ s/startEm//g;
                    }
                    $sentence =~ s/beginQuote /\"/g;
                    $sentence =~ s/ endQuote/\" /g;
                    $sentence =~ s/"endQuote //g;
                    $sentenceHold = $sentence;
                    my @sentArray = split( /\s+/, $sentenceHold );
                    $sentence = "";
                    for my $i ( 0 .. $#sentArray ) {

                        if (   $sentArray[ $i + 1 ] eq "\,"
                            || $sentArray[ $i + 1 ] eq "\'"
                            || $sentArray[ $i + 1 ] eq "\;"
                            || $sentArray[ $i + 1 ] eq "\:"
                            || $sentArray[ $i + 1 ] eq "\%"
                            || $sentArray[ $i + 1 ] eq "\]"
                            || $sentArray[ $i + 1 ] eq "\)"
                            || $sentArray[ $i + 1 ] eq "\}"
                            || $sentArray[ $i + 1 ] eq "\""
                            || $sentArray[ $i + 1 ] eq "\?"
                            || $sentArray[ $i + 1 ] eq "\!" )
                        {
                            $sentence .= "$sentArray[$i]";
                        }
                        elsif (
                            $i > 0
                            && (   $sentArray[$i] eq "\,"
                                && $sentArray[ $i - 1 ] =~ /\d/
                                && $sentArray[ $i + 1 ] =~ /\d/ )
                          )
                        {
                            $sentence .= "$sentArray[$i]";
                        }
                        elsif (
                            $i > 0
                            && (   $sentArray[$i] eq "\:"
                                && $sentArray[ $i - 1 ] =~ /\d/
                                && $sentArray[ $i + 1 ] =~ /\d/ )
                          )
                        {
                            $sentence .= "$sentArray[$i]";
                        }
                        elsif ($sentArray[$i] eq "\:"
                            || $sentArray[$i] eq "\?"
                            || $sentArray[$i] eq "\!" )
                        {
                            $sentence .= "$sentArray[$i]  ";
                        }
                        elsif ($sentArray[$i] eq "\'"
                            || $sentArray[$i] eq "\@"
                            || $sentArray[$i] eq "\#"
                            || $sentArray[$i] eq "\$"
                            || $sentArray[$i] eq "\["
                            || $sentArray[$i] eq "\("
                            || $sentArray[$i] eq "\("
                            || $sentArray[$i] eq "\{" )
                        {
                            $sentence .= "$sentArray[$i]";
                        }
                        elsif ($i == $#sentArray
                            && $sentArray[$i] ne ""
                            && $sentArray[$i] ne " " )
                        {
                            $sentence .= "$sentArray[$i]";
                        }
                        elsif ( $sentArray[$i] ne "" && $sentArray[$i] ne " " )
                        {
                            $sentence .= "$sentArray[$i] ";
                        }
                    }
                    if ($flag == 0) {
                        $sentence .= ".";
                    }
                    $sentence .= "\n";
                    if (   $sentence =~ /\"\"/
                        || $sentence =~ /\" \"/
                        || $sentence =~ /\"  \"/ )
                    {
                        $sentence =~ s/\"\"//g;
                        $sentence =~ s/\" \"//g;
                        $sentence =~ s/\"  \"//g;
                        $sentence =~ s/ \"\"//g;
                        $sentence =~ s/ \" \"//g;
                        $sentence =~ s/ \"  \"//g;
                        $sentence =~ s/ \"\" / /g;
                        $sentence =~ s/ \" \" / /g;
                        $sentence =~ s/ \"  \" / /g;
                    }
                    if ( $sentence =~ /amp;/ ) {
                        $sentence =~ s/amp;//g;
                        $sentence =~ s/ amp;//g;
                        $sentence =~ s/ amp; / /g;
                    }
                    $sentence =~ s/\"\./\.\"/g;
                    $sentence =~ s/\"\!/\!\"/g;
                    $sentence =~ s/\"\?/\?\"/g;
                    $sentence =~ s/endQuote //g;
                    $sentence =~ s/beginQuote //g;
                    last;
                }
            }
        }
    }

    push @paragraph, $sentence;
}

#Looping through and printing the generated sentences.
for my $i ( 0 .. $sentences ) {
    print @paragraph[$i];
    print "\n";
}

#The algorithm that generates the next word of the n-gram for any n > 1.
sub ContinueSentence() {
    my $count     = $hash{$prevWords}{'_total'};
    my $intRandom = int( rand( $count - 1 ) );
    my $word      = $hash{$prevWords}{ $intRandom + 1 };
    push @history, $word;
    return $word;
}

#The specific algorithm for n = 1 because the unigram structure needed to be modified for my hash distribution idea to function with it
#(a unigram doesnt have previous words, etc.)
sub ContinueSentenceUni() {
    my $count     = $unigrams{'_total'};
    my $intRandom = int( rand( $count - 1 ) );
    my $word      = $unigrams{ $intRandom + 1 };
    if ( $word eq "" || $word eq " " ) {
        $word = "endPd";
    }
    return $word;
}

#Constructing the previous words by playing with the array of last stored words generated.
sub GetPrevWords() {
    my @historyCopy = @history;
    $prevWords = "";
    for ( my $i = 0 ; $i < ( $n - 1 ) ; $i++ ) {
        my $holder = $prevWords;
        $prevWords = pop @historyCopy;
        $prevWords = $prevWords . $holder;
    }
}

#For use with constructing a new start token if a sentence needs to be zeroed out or restarted.
sub StartArray() {
    @history = ();
    my $int = int( rand(3) );
    if ( $int == 0 ) {
        for my $i ( 0 .. $n ) {
            push @history, "startPd ";
        }
    }
    elsif ( $int == 1 ) {
        for my $i ( 0 .. $n ) {
            push @history, "startEm ";
        }
    }
    else {
        for my $i ( 0 .. $n ) {
            push @history, "startQm ";
        }
    }
}

