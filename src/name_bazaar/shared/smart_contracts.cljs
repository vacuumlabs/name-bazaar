(ns name-bazaar.shared.smart-contracts) 

(def smart-contracts 
{:auction-offering-factory
 {:name "AuctionOfferingFactory",
  :address "0xabb67a671106ef23ee7a542a6c3e47d34b93e260"},
 :buy-now-offering-factory
 {:name "BuyNowOfferingFactory",
  :address "0x098c08052e6534ed8fae1eeb7f62cf2114139d06"},
 :name-bazaar-registrar
 {:name "NameBazaarRegistrar",
  :address "0x3425b296507b8681f31accf167c03eca10c2315e"},
 :buy-now-offering
 {:name "BuyNowOffering",
  :address "0x7d749c23c048e913842dc536e5e207e604b85379"},
 :reverse-registrar
 {:name "ReverseRegistrar",
  :address "0x9062C0A6Dbd6108336BcBe4593a3D1cE05512069"},
 :public-resolver
 {:name "PublicResolver",
  :address "0x5FfC014343cd971B7eb70732021E26C35B744cc4"},
 :ens
 {:name "ENSRegistry",
  :address "0x8ad81bd99d1ff39c5e4dd546bf3f9bfcf7d41d89"},
 :offering-registry
 {:name "OfferingRegistry",
  :address "0x2dab928e167a9d956449b860889e6cc41efade8d"},
 :district0x-emails
 {:name "District0xEmails",
  :address "0x7da654d62dc10dcad5f5ca083b74e9290e24f7d7"},
 :offering-requests
 {:name "OfferingRequests",
  :address "0x6f3bd83c692e3ab074e42aa8ef98c21a720a7d39"},
 :auction-offering
 {:name "AuctionOffering",
  :address "0x9ccf605741d61a75bef8ce60b14139fcf67fd499"}})