SimpleNavigation::Configuration.run do |navigation|

  navigation.renderer = SimpleNavigation::Renderer::Bootstrap


  navigation.items do |menu|
    navigation.autogenerate_item_ids = false
    navigation.selected_class = 'active'
    #navigation.name_generator = Proc.new {|icon| "<i class='#{icon}'></i>"}
    menu.dom_class = 'nav metismenu'
    menu.dom_id="side-menu"

    #navigation.active_leaf_class = 'collapse'

    menu.item :menu_1,"Cadastros Básicos", "#" do |menu_1|
      menu_1.dom_class = "nav nav-second-level"      
      menu_1.item :menu_1_1, 'Gerais', "#" do |menu_1_1|
        menu_1_1.dom_class = "nav nav-third-level"
        menu_1_1.item :menu_1_1_1, 'Domínios', dominios_path
        # menu_1_1.item :menu_1_1_2, 'Editar Usuário', edit_user_registration_path
        menu_1_1.item :menu_1_1_3, 'Empresas', empresas_path
      end
    end

    menu.item :menu_2, "Movimentos", "#" do |menu_2|
      menu_2.dom_class = "nav nav-second-level"
      menu_2.item :menu_2_1, "Notas Fiscais", nota_fiscais_path
    end
  end
  

end