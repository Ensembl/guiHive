package msg;

use strict;
use warnings;
use Data::Dumper;
use JSON;

sub new {
    my ($class) = @_;
    my $self = bless({}, $class);
    $self->init();
    return $self;
}

sub init {
    my ($self) = @_;
    $self->err_msg("");
    $self->status("ok");
    $self->out_msg("");
    return;
}

sub err_msg {
    my ($self, $msg) = @_;
    $self->{err_msg} = $msg if (defined $msg);
    return $self->{err_msg};
}

sub status {
    my ($self, $status) = @_;
    $self->{status} = $status if (defined $status);
    return $self->{status};
}

sub out_msg {
    my ($self, $out_msg) = @_;
    $self->{out_msg} = $out_msg if (defined $out_msg);
    return $self->{out_msg};
}

sub TO_JSON {
    my ($self) = @_;
    return { %$self };
}

sub toJSON {
    my ($self) = @_;
    return JSON->
	new->
	indent(0)->
	allow_blessed->
	convert_blessed->encode($self);
}

1;
