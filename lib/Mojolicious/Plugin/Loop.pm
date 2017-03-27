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

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Loop - Loop plugin for Mojolicious

=head1 SYNOPSIS

=head2 Application

  use Mojolicious::Lite;
  plugin 'loop';

=head2 Template

  %= loop [1,2,3,4], begin
  ---
  val: <%= loop->val %> [<%= $_ %>]
  count: <%= loop->index %> + 1 = <%= loop->count %> (index + 1)
  size: <%= loop->max %> + 1 = <%= loop->size %> (max + 1)
  prev: <%= loop->peek(-1) // 'undef' %> (peek -1)
  next: <%= loop->peek(1) // 'undef' %> (peek +1)
  parity: <%= loop->parity %>
  odd/even: <%= loop->odd ? 'odd' : loop->even ? 'even' : 'unknown' %>
  first: <%= loop->first ? 'yes' : 'no' %>
  last: <%= loop->last ? 'yes' : 'no' %>
  % end

  %= loop {a => 1, b => 2, c => 3}, begin
  ---
  val: <%= loop->val %> [<%= $_ %>]
  count: <%= loop->index %> + 1 = <%= loop->count %> (index + 1)
  size: <%= loop->max %> + 1 = <%= loop->size %> (max + 1)
  prev: <%= loop->peek(-1) // 'undef' %> (peek -1)
  next: <%= loop->peek(1) // 'undef' %> (peek +1)
  parity: <%= loop->parity %>
  odd/even: <%= loop->odd ? 'odd' : loop->even ? 'even' : 'unknown' %>
  first: <%= loop->first ? 'yes' : 'no' %>
  last: <%= loop->last ? 'yes' : 'no' %>
  % end

=head1 DESCRIPTION

L<Mojolicious::Plugin::Loop> is a plugin with helpers for iterating over data structures.

=head1 METHODS

=head2 count

=head2 even

=head2 first

=head2 index

=head2 last

=head2 max

=head2 odd

=head2 parity

=head2 peek

=head2 register

=head2 size

=head2 val

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Template::Iterator>.

=cut
