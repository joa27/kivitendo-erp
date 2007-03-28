package SL::DBUtils;

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(conv_i conv_date conv_dateq do_query selectrow_query do_statement
             dump_query quote_db_date selectall_hashref_query 
             selectfirst_hashref_query selectfirst_array_query 
             prepare_execute_query);

sub conv_i {
  my ($value, $default) = @_;
  return (defined($value) && "$value" ne "") ? $value * 1 : $default;
}

sub conv_date {
  my ($value) = @_;
  return (defined($value) && "$value" ne "") ? $value : undef;
}

sub conv_dateq {
  my ($value) = @_;
  if (defined($value) && "$value" ne "") {
    $value =~ s/\'/\'\'/g;
    return "'$value'";
  }
  return "NULL";
}

sub do_query {
  my ($form, $dbh, $query) = splice(@_, 0, 3);

  dump_query(LXDebug::QUERY, '', $query . " (" . join(", ", @_) . ")", @_);

  if (0 == scalar(@_)) {
    $dbh->do($query) || $form->dberror($query);
  } else {
    $dbh->do($query, undef, @_) ||
      $form->dberror($query . " (" . join(", ", @_) . ")");
  }
}

sub selectrow_query { &selectfirst_array_query }

sub do_statement {
  my ($form, $sth, $query) = splice(@_, 0, 3);

  dump_query(LXDebug::QUERY, '', $query . " (" . join(", ", @_) . ")", @_);

  if (0 == scalar(@_)) {
    $sth->execute() || $form->dberror($query);
  } else {
    $sth->execute(@_) ||
      $form->dberror($query . " (" . join(", ", @_) . ")");
  }
}

sub dump_query {
  my ($level, $msg, $query) = splice(@_, 0, 3);

  while ($query =~ /\?/) {
    my $value = shift(@_);
    $value =~ s/\'/\\\'/g;
    $value = "'${value}'";
    $query =~ s/\?/$value/;
  }

  $query =~ s/[\n\s]+/ /g;

  $msg .= " " if ($msg);

  $main::lxdebug->message($level, $msg . $query);
}

sub quote_db_date {
  my ($str) = @_;

  return "NULL" unless defined $str;
  return "current_date" if $str =~ /current_date/;

  $str =~ s/'/''/g;
  return "'$str'";
}

sub prepare_execute_query {
  my ($form, $dbh, $query) = splice(@_, 0, 3);

  dump_query(LXDebug::QUERY, '', $query . " (" . join(", ", @_) . ")", @_);

  my $sth = $dbh->prepare($query) || $form->dberror($query);
  if (scalar(@_) != 0) {
    $sth->execute(@_) || $form->dberror($query . " (" . join(", ", @_) . ")");
  } else {
    $sth->execute() || $form->dberror($query);
  }

  return $sth;
}

sub selectall_hashref_query {
  my ($form, $dbh, $query) = splice(@_, 0, 3);

  dump_query(LXDebug::QUERY, '', $query . " (" . join(", ", @_) . ")", @_);

  my $sth = prepare_execute_query($form, $dbh, $query, @_);
  my $result = [];
  while (my $ref = $sth->fetchrow_hashref()) {
    push(@{ $result }, $ref);
  }
  $sth->finish();

  return $result;
}

sub selectfirst_hashref_query {
  my ($form, $dbh, $query) = splice(@_, 0, 3);

  dump_query(LXDebug::QUERY, '', $query . " (" . join(", ", @_) . ")", @_);

  my $sth = prepare_execute_query($form, $dbh, $query, @_);
  my $ref = $sth->fetchrow_hashref();
  $sth->finish();

  return $ref;
}

sub selectfirst_array_query {
  my ($form, $dbh, $query) = splice(@_, 0, 3);

  dump_query(LXDebug::QUERY, '', $query . " (" . join(", ", @_) . ")", @_);

  my $sth = prepare_execute_query($form, $dbh, $query, @_);
  my @ret = $sth->fetchrow_array();
  $sth->finish();

  return @ret;
}

1;


__END__

=head1 NAME

SL::DBUTils.pm: All about Databaseconections in Lx

=head1 SYNOPSIS

  use DBUtils;
  
  conv_i
  conv_date
  conv_dateq
  quote_db_date($str)

  do_query($form, $dbh, $query)
  do_statement($form, $sth, $query)

  dump_query($level, $msg, $query)
  prepare_execute_query($form, $dbh, $query)

  my $all_results_ref       = selectall_hashref_query($form, $dbh, $query)
  my $first_result_hash_ref = selectfirst_hashref_query($form, $dbh, $query);
  
  my @first_result =  selectfirst_array_query($form, $dbh, $query);  # ==
  my @first_result =  selectrow_query($form, $dbh, $query);
  
    
=head1 DESCRIPTION
  
=head1 FUNCTIONS
  
=over 4
  
=item conv_i

=item conv_date

=item conv_dateq

=item quote_db_date($str)

=item do_query($form, $dbh, $query)

=item do_statement($form, $sth, $query)

=item dump_query($level, $msg, $query)

=item prepare_execute_query($form, $dbh, $query)

=item selectall_hashref_query($form, $dbh, $query)

=item selectfirst_hashref_query($form, $dbh, $query);

=item selectfirst_array_query($form, $dbh, $query);  # ==

=item selectrow_query($form, $dbh, $query);
  
=back
  
=head1 EXAMPLE

=head1 SEE ALSO

=head1 MODULE AUTHORS

Sven Schoeling
 
=head1 DOCUMENTATION AUTHORS

Udo Spallek  E<lt>udono@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Lx-Office Community

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
=cut    