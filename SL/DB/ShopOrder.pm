# This file has been auto-generated only because it didn't exist.
# Feel free to modify it at will; it will not be overwritten automatically.

package SL::DB::ShopOrder;

use strict;

use SL::DB::MetaSetup::ShopOrder;
use SL::DB::Manager::ShopOrder;
use SL::DB::Helper::LinkedRecords;
use SL::Locale::String qw(t8);

__PACKAGE__->meta->add_relationships(
  shop_order_items => {
    class      => 'SL::DB::ShopOrderItem',
    column_map => { id => 'shop_order_id' },
    type       => 'one to many',
  },
  customer => {
    class     => 'SL::DB::Customer',
    column_map  => { kivi_customer_id => 'id' },
    type        => 'one to many',
  },
  shop => {
    class     => 'SL::DB::Shop',
    column_map  => { shop_id => 'id' },
    type        => 'one to many',
  },
);

__PACKAGE__->meta->initialize;

sub convert_to_sales_order {
  my ($self, %params) = @_;

  my $customer = $params{customer};
  my $employee = $params{employee};
  die unless ref($customer) eq 'SL::DB::Customer';
  die unless ref($employee) eq 'SL::DB::Employee';

  require SL::DB::Order;
  require SL::DB::OrderItem;
  require SL::DB::Part;
  require SL::DB::Shipto;
  my @error_report;

  my @items = map{

  # TODO Flash and exit if part not found
    my $part = SL::DB::Manager::Part->get_first( query => [ partnumber => $_->partnumber, ], );

    unless($part){
      push @error_report, t8('Part with Partnumber: ') . $_->partnumber . t8(' not found');
    }else{
      my $shop_part = SL::DB::Manager::ShopPart->get_all( where => [ shop_id => $self->shop_id, part_id => $part->id] )->[0];

      my @cvars = map { ($_->config->name => { value => $_->value_as_text, is_valid => $_->is_valid }) } @{ $part->cvars_by_config } ;
      my $current_order_item =
        SL::DB::OrderItem->new(parts_id               => $part->id,
                               description            => $part->description,
                               qty                    => $_->quantity,
                               sellprice              => $_->price,
                               unit                   => $part->unit,
                               position               => $_->position,
                               active_price_source    => $shop_part->active_price_source,
                             );
    }
  }@{ $self->shop_order_items };

  if(!scalar(@error_report)){

    my $shipto_id;
    if ($self->{billing_firstname} ne $self->{delivery_firstname} || $self->{billing_lastname} ne $self->{delivery_lastname} || $self->{billing_city} ne $self->{delivery_city} || $self->{billing_street} ne $self->{delivery_street}) {
      if(my $address = SL::DB::Manager::Shipto->find_by( shiptoname          => $self->{delivery_firstname} . " " . $self->{delivery_lastname},
                                                          shiptostreet        => $self->{delivery_street},
                                                          shiptocity          => $self->{delivery_city},
                                                        )) {
        $shipto_id = $address->{shipto_id};
      } else {
        my $deliveryaddress = SL::DB::Shipto->new;
        $deliveryaddress->assign_attributes(
          shiptoname          => $self->{delivery_firstname} . " " . $self->{delivery_lastname},
          shiptodepartment_1  => $self->{delivery_company},
          shiptodepartment_2  => $self->{delivery_department},
          shiptostreet        => $self->{delivery_street},
          shiptozipcode       => $self->{delivery_zipcode},
          shiptocity          => $self->{delivery_city},
          shiptocountry       => $self->{delivery_country},
          trans_id            => $customer->id,
          module              => "CT",
        );
        $deliveryaddress->save;
        $shipto_id = $deliveryaddress->{shipto_id};
      }
    }

    my $order = SL::DB::Order->new(
                    amount                  => $self->amount,
                    cusordnumber            => $self->shop_ordernumber,
                    customer_id             => $customer->id,
                    shipto_id               => $shipto_id,
                    orderitems              => [ @items ],
                    employee_id             => $employee->id,
                    intnotes                => ($customer->notes ne "" ? "\n[Kundestammdaten]\n" . $customer->notes : ""),
                    salesman_id             => $employee->id,
                    taxincluded             => $self->tax_included,
                    payment_id              => $customer->payment_id,
                    taxzone_id              => $customer->taxzone_id,
                    currency_id             => $customer->currency_id,
                    transaction_description => 'Shop Import',
                    transdate               => DateTime->today_local
                  );
     return $order;
   }else{
     my %error_order = (error   => 1,
                        errors  => [ @error_report ],
                );
     return \%error_order;
   }
};

sub compare_to {
  my ($self, $other) = @_;

  return  1 if  $self->transfer_date && !$other->transfer_date;
  return -1 if !$self->transfer_date &&  $other->transfer_date;

  my $result = 0;
  $result    = $self->transfer_date <=> $other->transfer_date if $self->transfer_date;
  return $result || ($self->id <=> $other->id);
}

1;