# frozen_string_literal: true

class NpcSerializer < RealmLocationSerializer
  attributes :species, :gender, :role, :portrait
  attributes :shop_type, :buy_offers, :sell_offers if :shop?

  def portrait
    object.portrait.name
  end

  def buy_offers
    offers = object.buy_offers(instance_options[:user])
    ActiveModelSerializers::SerializableResource.new(offers, each_serializer: TradeOfferSerializer)
  end

  def sell_offers
    offers = object.sell_offers
    ActiveModelSerializers::SerializableResource.new(offers, each_serializer: TradeOfferSerializer)
  end
end
