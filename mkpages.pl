#!/usr/bin/perl -w

my @files = `find ../Haraka-publish -type f -name \*.md`;
chomp(@files);

sub sort_order {
    my ($filea, $fileb) = @_;
    if ($filea =~ /README/) {
        return -1;
    }
    if ($fileb =~ /README/) {
        return +1;
    }
    if ($filea =~ /\/tutorial/i) {
        return -1;
    }
    if ($filea =~ /\/plugins\//) {
        return +1;
    }
    return 0;
}

sub output {
    my $in = shift;
    $in =~ s/.*\/docs/manual/;
    $in =~ s/.*Haraka-publish\///;
    $in =~ s/\.md$/.html/;
    return $in;
}

sub dirname {
    my $in = shift;
    $in =~ s/[^\/]*$//;
    return $in;
}

sub convert {
    my $file = shift;
    open(my $fh, "./Markdown.pl $file |") || die "Cannot run Markdown.pl: $!";
    local $/;
    my $md2html = <$fh>;
    return $md2html;
}

my $wrapper = `cat template.html`;

my $chapter_out = '';
my $plugins_sent = 0;
my $tutorials_sent = 0;
my $core_sent = 0;

for my $file (sort { sort_order($a, $b) } @files) {
    my $out = output($file);
    print "Processing $file => $out\n";
    system("mkdir", "-p", dirname($out)) unless $file =~ /README/;
    open(my $outfh, ">", $out);

    my $output = convert($file);

    my ($title) = ($output =~ /<h1>([^<]*)/);
    $title ||= "Haraka";
    # $title .= " plugin" if $out =~ /plugin/;

    my $template = $wrapper;
    $template =~ s/<\%=\s*title\s*\%>/$title/g;
    $template =~ s/<\%=\s*content\s*\%>/$output/g;

    print $outfh $template;
    close($outfh);

    if (!$plugins_sent && $out =~ /plugin/) {
        $plugins_sent++;
        $chapter_out .= "<hr>\n";
        $chapter_out .= "<h2>Plugins</h2>\n";
    }
    elsif (!$tutorials_sent && $out =~ /tutorial/i) {
        $tutorials_sent++;
        $chapter_out .= "<hr>\n<h2>Tutorials</h2>\n";
    }
    elsif ($out !~ /(tutorial|plugin)/i && !$core_sent) {
        $core_sent++;
        $chapter_out .= "<hr>\n<h2>Core</h2>\n";
    }

    $chapter_out .= "<li><a href='/$out' target=\"content\">$title</a></li>\n";
}

my $chapter_template = `cat chapter-index-template.html`;

open(my $outfh, ">", "manual/chapter-index.html") || die $!;

$chapter_template =~ s/<\%=\s*content\s*\%>/$chapter_out/g;

print $outfh $chapter_template;
close($outfh);
