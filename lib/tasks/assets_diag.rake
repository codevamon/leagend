namespace :diag do
  desc "Imprime precompile list y rutas de Sprockets"
  task :assets => :environment do
    puts "=== DIAGNÓSTICO DE ASSETS ==="
    puts ""
    puts "precompile: #{Rails.application.config.assets.precompile.inspect}"
    puts ""
    puts "paths:"
    Rails.application.config.assets.paths.each do |path|
      puts "  - #{path}"
    end
    puts ""
    puts "=== VERIFICACIÓN DE IMPORTMAP ==="
    puts ""
    puts "Importmap configurado: #{Rails.application.config.importmap.present?}"
    puts "Controllers disponibles:"
    Dir.glob(Rails.root.join("app/javascript/controllers/*_controller.js")).each do |file|
      puts "  - #{File.basename(file)}"
    end
    puts ""
    puts "=== VERIFICACIÓN DE LAYOUT ==="
    puts ""
    layout_file = Rails.root.join("app/views/layouts/application.html.erb")
    if File.exist?(layout_file)
      content = File.read(layout_file)
      puts "javascript_include_tag presente: #{content.include?('javascript_include_tag')}"
      puts "javascript_pack_tag presente: #{content.include?('javascript_pack_tag')}"
      puts "javascript_importmap_tags presente: #{content.include?('javascript_importmap_tags')}"
    else
      puts "Layout file no encontrado"
    end
  end
end
