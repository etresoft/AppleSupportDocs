#!/usr/bin/perl

use strict;

open(OUT, ">>output.xml");

print OUT "<articles>\n";

# Pull all known ranges of documents.
getpages('sp', 1, 1000);
#getpages('dl', 1, 2000);
#getpages('PH', 2000, 27000);
#getpages('HT', 200000, 210000);

sub getpages
  {
  my $code = shift;
  my $min = shift;
  my $max = shift;
  
  my $diff = $max - $min;
  
  return
    if $diff < 0;
      
  my $mid = $min + int(($max - $min)/2);

  my $found_mid = getpage($code, $mid);

  if($found_mid)
    {
    getfoundpagesdown($code, $min, $mid - 1);
    getfoundpagesup($code, $mid + 1, $max);
    }
  else
    {
    return
      if $diff < ($diff / 100);
      
    getpages($code, $min, $mid - 1);
    getpages($code, $mid + 1, $max);
    }
  }

sub getfoundpagesup
  {
  my $code = shift;
  my $min = shift;
  my $max = shift;
  
  my $current = $min;
  
  for(;$current < $max; ++$current)
    {
    last 
      if not getpage($code, $current);
    }
    
  getpages($code, $current + 1, $max)
    if $current < $max;
  }

sub getfoundpagesdown
  {
  my $code = shift;
  my $min = shift;
  my $max = shift;
  
  my $current = $max;
  
  for(;$current >= $min; --$current)
    {
    last 
      if not getpage($code, $current);
    }
    
  getpages($code, $min, $current)
    if $current > $min;
  }

sub getpage
  {
  my $code = shift;
  my $id = shift;

  my $page = $code . $id;

  my $url = '';
  
  if($code eq 'HT')
    {
    $url = 'https://support.apple.com/en-us/' . $page;
    }
  else
    {
    $url = 'https://support.apple.com/kb/' . $page . '?locale=en_US';
    }
  
  my $cmd = "curl -s $url > $page.html";
  
  system($cmd);
  
  local $/;
  
  open(IN, "$page.html");
  
  my $data = <IN>;
  
  my ($title) = 
    $data
      =~ m|<h1 id="main-title"[^>]*>(.+)</h1>|gsm; 
  
  close(IN);
  
  if($title)
    {
    $title =~ s/\s&\s/ &amp; /g;

    print "found $title\t$url\n";
    print OUT "  <article>\n";
    print OUT "    <title>$title</title>\n";
    print OUT "    <url>$url</url>\n";
    print OUT "  </article>\n";
    
    return 1;
    }
  else
    {
    print "not found $title\t$url\n";
    unlink "$page.html";
  
    return 0;
    }
  }
  
print OUT "</articles>\n";

close(OUT);
