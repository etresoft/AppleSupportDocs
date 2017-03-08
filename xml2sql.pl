#!/usr/bin/perl

use strict;

use Getopt::Long;
use XML::Parser::Expat;
use DBI;

my $connection;
my $user;
my $password;

GetOptions(
  'db=s' => \$connection,
  'user=s' => \$user,
  'password=s' => \$password
  );

my $input = shift;

die usage()
  if !-f $input;

# Create an Expat stream parser.
my $parser = new XML::Parser::Expat(Style => 'Stream');

# Keep track of title, url, and text.
my $state =
  {
  title => undef,
  url => undef,
  emitText => undef,
  text => undef
  };
  
# Setup the parser.
$parser->setHandlers(
  Start => \&start,
  End => \&end,
  Char => \&text
  );

my $db = DBI->connect($connection, $user, $password, { RaiseError => 1 });

# Setup the database.
setupdb();

my $insert = 
  $db->prepare(
    "INSERT INTO documents(category, title, url) VALUES (?, ?, ?)");

# Fire it up!
$parser->parsefile($input);

$db->disconnect;

# Handle a start element.
sub start
  {
  my $expat = shift;
  my $element = shift;
  my %attributes = @_;
 
  # Capture text for the title.
  if($element eq 'title')
    {
    $state->{emitText} = 1;
    }

  # Capture text for the url.
  elsif($element eq 'url')
    {
    $state->{emitText} = 1;
    }
  }
  
# Handle an end element.
sub end
  {
  my $expat = shift;
  my $element = shift;

  $state->{text} =~ s/\s*(.+)\s*/$1/;

  if($element eq 'title')
    {
    $state->{title} = $state->{text};
    }
  elsif($element eq 'url')
    {
    $state->{url} = $state->{text};
    }
  elsif($element eq 'article')
    {
    my ($category) = $state->{title} =~ /^([^:]+)\s*:.+$/;

    $insert->execute($category, $state->{title}, $state->{url});
    }
    
  # I must be done.
  $state->{emitText} = 0;
  $state->{text} = undef;
  }
  
# Handle a text node.
sub text
  {
  my $expat = shift;
  my $string = shift;

  $state->{text} = ($state->{text} || '') . $string;
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

  $db->do($create);
  }

sub usage
  {
  return << 'EOS';
Usage: xml2sql.pl <xml file to convert> [options...]
  where [options...] are:
    db = DBI database connection string
    user = Database user 
    password = Database password
EOS
  }
