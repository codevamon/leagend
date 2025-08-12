# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "@rails/ujs", to: "@rails--ujs.js" # @7.1.3
pin "flatpickr", to: "https://cdn.skypack.dev/flatpickr"
pin_all_from "app/javascript/controllers", under: "controllers"
