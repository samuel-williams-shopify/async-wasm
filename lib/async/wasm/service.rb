require "async"
require "io/endpoint/bound_endpoint"
require "async/service"
require "async/container/supervisor"

require_relative "server"

module Async
  module WASM
    class Service < Async::Service::Generic
      def preload!
      end

      # Prepare the bound endpoint for the server.
			def start
				@endpoint = @evaluator.endpoint
				
				Sync do
					@bound_endpoint = @endpoint.bound
				end
				
				preload!
				
				Console.logger.info(self) {"Starting #{self.name} on #{@endpoint}"}
				
				super
			end
      
      # Close the bound endpoint.
			def stop(...)
				if @bound_endpoint
					@bound_endpoint.close
					@bound_endpoint = nil
				end
				
				@endpoint = nil
				
				super
			end
      
      def setup(container)
        super

				container_options = @evaluator.container_options
				health_check_timeout = container_options[:health_check_timeout]
				
				container.run(name: self.name, **container_options) do |instance|
					evaluator = @environment.evaluator
					
					Async do |task|
						if @environment.implements?(Async::Container::Supervisor::Supervised)
							evaluator.make_supervised_worker(instance).run
						end
						
						server = evaluator.make_server(@bound_endpoint)
						
						server.run
						
						instance.ready!
						
						if health_check_timeout
							Async(transient: true) do
								while true
									sleep(health_check_timeout / 2)
									instance.ready!
								end
							end
						end
						
						task.children.each(&:wait)
					end
        end
      end
    end
  end
end
