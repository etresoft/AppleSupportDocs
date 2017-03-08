#!/usr/bin/perl

use strict;

open(OUT, ">>output.xml");

print OUT "<articles>\n";

# Adjust this value to locate all likely articles.
getpages(131249, 300000);

sub getpages
  {
  my $min = shift;
  my $max = shift;
  
  my $diff = $max - $min;
  
  return
    if $diff < 0;
      
  my $mid = $min + int(($max - $min)/2);

  my $found_mid = getpage($mid);

  if($found_mid)
    {
    getfoundpagesdown($min, $mid - 1);
    getfoundpagesup($mid + 1, $max);
    }
  else
    {
    return
      if $diff < 1000;
      
    getpages($min, $mid - 1);
    getpages($mid + 1, $max);
    }
  }

sub getfoundpagesup
  {
  my $min = shift;
  my $max = shift;
  
  my $current = $min;
  
  for(;$current < $max; ++$current)
    {
    last 
      if not getpage($current);
    }
    
  getpages($current + 1, $max)
    if $current < $max;
  }

sub getfoundpagesdown
  {
  my $min = shift;
  my $max = shift;
  
  my $current = $max;
  
  for(;$current >= $min; --$current)
    {
    last 
      if not getpage($current);
    }
    
  getpages($min, $current)
    if $current > $min;
  }

sub getpage
  {
  my $id = shift;

  my $page = '';

  my $url = '';
  
  if($id > 200000)
    {
    $page = 'HT' . $id;
    $url = 'https://support.apple.com/en-us/' . $page;
    }
  elsif($id < 2200)
    {
    $page = 'dl' . $id;
    $url = 'https://support.apple.com/kb/' . $page . '?locale=en_US';
    }
  else
    {
    $page = 'PH' . $id;
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
