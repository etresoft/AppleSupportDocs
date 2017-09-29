#!/usr/bin/perl

use strict;

use Getopt::Long;
use DBI;

my $connection;
my $user;
my $password;

GetOptions(
  'db=s' => \$connection,
  'user=s' => \$user,
  'password=s' => \$password
  );

my $url = shift;

die usage()
  if not $url;

my $db = DBI->connect($connection, $user, $password, { RaiseError => 1 });

# Setup the database.
setupdb();

my $insert = 
  $db->prepare(
    "INSERT INTO documents(category, title, url) VALUES (?, ?, ?)");

# Fire it up!
download();

$db->disconnect;

# Download a document.
sub download
  {
  system("mkdir -p html");
  
  my ($page) = $url =~ m|.+/(..\d+)$|;

  my $cmd = "curl -L -s $url > html/$page.html";
  
  system($cmd);
  
  local $/;
  
  open(IN, "html/$page.html");
  
  my $data = <IN>;
  
  my ($title) = $data =~ m|<h1 id="main-title"[^>]*>(.+)</h1>|gsm; 
  
  close(IN);
  
  if($title)
    {
    $title =~ s/\s&\s/ &amp; /g;

    my ($category) = $title =~ /^([^:]+)\s*:.+$/;

    print "Saving $url ";

    eval
      {
      $insert->execute($category, $title, $url);

      print "successful\n";
      };

    print "failed $@\n" 
      if $@;
    }
  else
    {
    print "not found $title\t$url\n";
    unlink "html/$page.html";
    }
  }

# Setup the database.
sub setupdb
  {
  my $create = << 'EOS';
create table if not exists documents
  (
  category text,
  title text,
  url text
  )
EOS

  my $index = "create unique index if not exists url on documents (url);";

  $db->do($index);

  $index = "create index if not exists category on documents (category);";

  $db->do($index);

  $index = "create index if not exists title on documents (title);";

  $db->do($index);
  }

sub usage
  {
  return << 'EOS';
Usage: download.pl <URL> [options...]
  where [options...] are:
    db = DBI database connection string
    user = Database user 
    password = Database password

  Example: perl download.pl https://support.apple.com/HT206184 --db=dbi:SQLite:../documents.db
EOS
  }
