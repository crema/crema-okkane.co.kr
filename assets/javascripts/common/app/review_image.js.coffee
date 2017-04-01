class @ReviewImage
  constructor: ->
    @enabled = true
    @$root = $(".image-fields-container")
    @max_images_count = @$root.data("max-images-count")
    @images_count = @$root.data("images-count")

    $(document).on "change", "input.input-file", (e) => @on_select_image(e.target)
    $(document).on "click", ".remove-preview, .image-field__remove_image", (e) => @on_remove_image(e.target)
    $(document).on "click", ".add_image_container", => @add_image_container()

  set_enabled: (enabled) ->
    @enabled = enabled

  set_form: ($form) ->
    @$root = $form.find(".image-fields-container")
    @images_count = @$root.data("images-count")
    @max_images_count = @$root.data("max-images-count")
    $form.bind "ajax:error", (e, xhr) ->
      if xhr.responseText && xhr.responseText.match(/^413/)
        alert(lib.i18n.t("image_size_too_large"))

  on_select_image: (input) ->
    if !@enabled
      return true

    $input = $(input)
    if !@image_field_validate($input)
      return

    $preview_container = $input.siblings(".preview-container")
    $preview = $preview_container.find("img.preview")
    if !lib.browser.supports_file_reader()
      $input_image_container = $input.siblings(".input-image-container")
      $input_image_container.hide()

      $parent = $input.parent()
      lib.ui_util.set_waiting($parent)

      $form = $("#upload-image")
      url_builder = new UrlBuilder($input.data("upload-image-url"))
      url_builder.add_param("input_id", $input.attr("id"))
      $form.attr("action", url_builder.build())
      $input.data("name", $input.attr("name"))
      $input.attr("name", "file")
      $form.find(".fields_container").empty().append($input)

      complete = ->
        $form.unbind "ajax:success ajax:error"
        $input_image_container.show()
        lib.ui_util.clear_waiting($parent)

      $form.bind "ajax:success", (e, data) =>
        complete()
        @add_preview_image(data)

      $form.bind "ajax:error", (e) ->
        $input.val("")
        $parent.append($input)
        complete()

      $form.submit()
    else
      @select_images(input.files)

  select_images: (files) ->
    return unless files

    new_images_count = files.length
    remaining_images_count = @max_images_count - @images_count
    if remaining_images_count < new_images_count
      alert_message = @$root.data("limit-images-count-warning").replace(/%{max_count}/, @max_images_count).replace(/%{count}/, remaining_images_count)
      alert(alert_message)
      new_images_count = remaining_images_count

    offset = @images_count
    $links = $()
    $links = $links.add(@$root.find(".remove-preview").eq(offset))
    for i in [0...new_images_count] by 1
      $new_image_field = @set_preview_image()
      if i != new_images_count - 1
        $new_image_field.find("input.input-file").remove()
        $links = $links.add($new_image_field.find(".remove-preview"))
      @preview_image_data(files[i], offset + i)

    $links.click =>
      $links.each (i, e) => @on_remove_image($(e))
      false

  preview_image_data: (image_data, index) ->
    reader = new FileReader()
    reader.onload = (e) =>
      image = new Image()
      image.src = e.target.result
      image.onload = (e) =>
        $preview_container = @$root.find(".preview-container").eq(index)
        $preview_container.find("img.preview").css({
          backgroundImage: "url(" + e.target.src + ")",
          backgroundSize: "cover",
          backgroundPosition: "50%",
          height: "100%",
          width: "100%",
          color: "rgba(0,0,0,0)"
        })
        $preview_container.removeClass("hidden")

    reader.readAsDataURL(image_data)

  on_remove_image: (link) ->
    $link = $(link)
    $link.closest(".preview-container").addClass("hidden")
    $image_field = $link.closest(".image-field")

    $image_field.find(".wrap").removeClass("review-image-preview")

    $image_field.remove()

    @images_count -= 1
    if @images_count == @max_images_count - 1
      @add_new_image_field()

    if !lib.browser.supports_file_reader()
      $input_file = $("#upload-image .fields_container input")
      $image_field.find(".input-image-container").after($input_file)

  add_preview_image: (args) ->
    if args.input_id
      $input = $("#" + args.input_id)
    else
      $input = $("input.input-file").last()

    thumbnail_url = args.thumbnail_url
    filename = args.filename

    attribute_name = $input.data("name") || $input.attr("name")
    attribute_id = $input.attr("id")

    $image_field = @$root.find("li").last()

    $image_field.find(".wrap").addClass("review-image-preview")

    $input_image_container = $image_field.find(".input-image-container")
    $input_image_container.show()

    $preview_container = $image_field.find(".preview-container")
    $preview_container.before($("<input type='hidden'>").attr(name: attribute_name, id: attribute_id).val(filename))

    $preview = $preview_container.find("img.preview")
    $preview.attr("src", thumbnail_url).css("width", "100%")
    $preview_container.removeClass("hidden")
    @set_preview_image()

  set_preview_image: ->
    if @images_count < @max_images_count
      @images_count += 1

      if @images_count < @max_images_count
        @add_new_image_field()

  image_field_validate: ($input) ->
    app.image_field_validator.validate($input)

  add_new_image_field: ->
    $(Mustache.render(@$root.closest("form").find(".new-image-field").html())).appendTo(@$root)

  add_image_container: ->
    if @images_count < @max_images_count
      offset = $("input[type=hidden][name='review[images][]']").length
      @$root.find("input[type=file]").eq(@images_count - offset).trigger("click")
    else
      alert(@$root.data("max-images-count-warning"))
