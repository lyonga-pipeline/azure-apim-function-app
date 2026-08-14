locals {
  eventgrid_subscription = { for index, subscription in var.eventgrid_subscription : subscription.name => {

    index : index,
    subscription : subscription
  } }
}