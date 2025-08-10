import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    // El controller se conecta cuando se carga la página
  }

  open(event) {
    // El modal se abre automáticamente con Turbo Frame
    // Este método puede usarse para lógica adicional si es necesario
    console.log("Modal abierto")
    
    // Resize del mapa después de que el modal esté visible
    setTimeout(() => {
      this.resizeMapInModal()
    }, 200) // Aumentar el delay para asegurar que el modal esté completamente visible
  }

  close(event) {
    // Cerrar el modal
    const modalElement = document.querySelector('.modal');
    if (modalElement) {
      // Remover backdrop
      const backdrop = document.querySelector('.modal-backdrop');
      if (backdrop) {
        backdrop.remove();
      }
      
      // Ocultar modal
      modalElement.style.display = 'none';
      modalElement.classList.remove('d-block');
      
      // Si usamos Bootstrap
      if (typeof window.bootstrap !== 'undefined' && window.bootstrap.Modal) {
        const modal = bootstrap.Modal.getInstance(modalElement);
        if (modal) modal.hide();
      }
    }
    
    // Limpiar el frame del modal
    const modalFrame = document.getElementById('modal');
    if (modalFrame) {
      modalFrame.innerHTML = '';
    }
    
    // Log para debugging
    console.log('Modal cerrado');
  }

  // Método para manejar la creación exitosa de arena
  arenaCreated(event) {
    // Este método se puede llamar desde el turbo_stream
    this.close();
  }

  // Resize del mapa dentro del modal
  resizeMapInModal() {
    console.log('Modal: intentando resize del mapa...');
    
    // Buscar el controlador arena-location
    const arenaLocationElement = document.querySelector('[data-controller="arena-location"]');
    if (!arenaLocationElement) {
      console.log('Modal: no se encontró elemento con data-controller="arena-location"');
      return;
    }
    
    const arenaLocationController = this.application.getControllerForElementAndIdentifier(
      arenaLocationElement,
      'arena-location'
    )
    
    if (arenaLocationController && typeof arenaLocationController.resizeMap === 'function') {
      console.log('Modal: controlador arena-location encontrado, ejecutando resizeMap');
      arenaLocationController.resizeMap()
    } else {
      console.log('Modal: no se encontró el controlador arena-location o método resizeMap');
      console.log('Controlador:', arenaLocationController);
      if (arenaLocationController) {
        console.log('Método resizeMap:', typeof arenaLocationController.resizeMap);
      }
    }
  }
}
