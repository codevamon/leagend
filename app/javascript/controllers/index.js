import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

import { application } from "./application"

import ModalController from "./modal_controller"
import ArenaLocationController from "./arena_location_controller"
import DuelFormController from "./duel_form_controller"

application.register("modal", ModalController)
application.register("arena-location", ArenaLocationController)
application.register("duel-form", DuelFormController)

window.Stimulus = Application.start()
eagerLoadControllersFrom("controllers", Stimulus)
