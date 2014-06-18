# -*- encoding : utf-8 -*-
require "mongoid"

ENV["MONGOID_ENV"] = "test"
Mongoid.load!("./spec/config/mongoid.yml")
