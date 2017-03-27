package Mojolicious::Plugin::Loop;
use Mojo::Base 'Mojolicious::Plugin';

our $ITERATOR;

sub count  { $_[0]->{index} + 1 }
sub even   { $_[0]->{index} % 2 ? 0 : 1 }
sub first  { $_[0]->{index} == 0 }
sub index  { $_[0]->{index} }
sub last   { $_[0]->{index} + 1 == @{$_[0]->{items}} }
sub max    { $_[0]->size - 1 }
sub odd    { $_[0]->{index} % 2 ? 1 : 0 }
sub parity { $_[0]->{index} % 2 ? 'odd' : 'even' }

sub peek {
  my ($self, $offset) = @_;
  my $index = $_[0]->{index} + $offset;
  return $index < 0 ? undef : $_[0]->{items}[$index];
}

sub size { int @{$_[0]->{items}} }
sub val { $_[0]->{map} ? $_[0]->{map}{$_[0]->{item}} : $_[0]->{item} }

sub register {
  my ($self, $app, $config) = @_;

  $app->helper(
    loop => sub {
      my ($c, $data, $cb) = @_;
      return $ITERATOR if @_ == 1;
      return Mojolicious::Plugin::Loop->_iterate($c->stash, $data, $cb);
    }
  );
}

sub _iterate {
  my ($class, $stash, $data, $cb) = @_;
  my $bs = Mojo::ByteStream->new;
  my $self = bless {cb => $cb}, $class;

  if (UNIVERSAL::isa($data, 'ARRAY')) {
    @$self{qw(items)} = ($data);
  }
  elsif (UNIVERSAL::isa($data, 'HASH')) {
    @$self{qw(items map)} = ([sort keys %$data], $data);
  }
  elsif (UNIVERSAL::can($data, 'to_array')) {
    @$self{qw(items)} = $data->to_array;
  }

  $self->{index} = -1;
  local $ITERATOR = $self;

LOOP:
  for (@{$self->{items}}) {
    local $self->{item} = $_;
    $self->{index}++;
    $bs .= $cb->();
  }

  return $bs;
}

1;
