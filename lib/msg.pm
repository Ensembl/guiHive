=pod

 Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.


=cut


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
