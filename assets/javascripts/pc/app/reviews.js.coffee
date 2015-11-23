class Reviews
  collapse = ($review_content, complete) ->
    $collapsed = $review_content.find(".review-content-collapsed").css(opacity: 0)
    $expanded = $review_content.find(".review-content-expanded").css(opacity: 1)
    $review_content.height($expanded.outerHeight() + 28)
    setTimeout (->
      $review_content.addClass("expanding")
      if $collapsed.length > 0
        lib.animation.fade_out $expanded, duration: "short"
        lib.animation.fade_in $collapsed, duration: "short", complete: ->
          $collapsed.css(opacity: 1)
          $expanded.hide()
          lib.animation.css $review_content, {
            from_css: {height: $expanded.height()},
            to_css: {height: $collapsed.height()},
            complete: ->
              $collapsed.css(opacity: "")
              $expanded.css(opacity: "", display: "")
              $review_content.removeClass("expanding expanded").css(height: "")
              complete() if complete
            }
      else
        lib.animation.fade_out $expanded, duration: "short", complete: ->
          $summary = $review_content.find(".review-content-summary")
          $expanded.hide()

          lib.animation.css $review_content, {
            from_css: {height: $expanded.height()},
            to_css: {height: $summary.height()},
            complete: ->
              $expanded.css(opacity: "", display: "")
              $review_content.removeClass("expanding expanded").css(height: "")
              complete() if complete
            }
        ), 1

  handle_link_expand: (args, auto_collapse) ->
    args.elements.find(".link-collapse").click ->
      collapse $(this).closest(".review-content")

    args.elements.find(".review-content").on "review_content:filled", (e) ->
      $review_content = $(e.target)
      $review_content.data("filled", true)
      $review_content.find(".link-collapse").click -> collapse $review_content
      $review_content.trigger "review_content:loaded"

    args.elements.find(".link-expand").click ->
      $review = $(this).closest(".review")
      $review_content = $review.find(".review-content")
      if !$review_content.hasClass("expanded")
        $review_content.on "review_content:loaded", (e) ->
          if $review_content.data("filled") && $review_content.data("ready")
            $collapsed = $review_content.find(".review-content-collapsed").css(opacity: 1)
            $expanded = $review_content.find(".review-content-expanded").css(opacity: 0)
            $review_content.height($review_content.height())
            $expanded.hide()
            setTimeout (->
              $review_content.addClass("expanded expanding")
              lib.animation.css $review_content, {
                to_css: {height: $expanded.outerHeight() + 28},
                complete: ->
                  lib.animation.fade_out $collapsed, duration: "short"
                  app.form.enable_validate()
                  $expanded.show()
                  lib.animation.fade_in $expanded, duration: "short", complete: ->
                    $collapsed.css(opacity: "")
                    $expanded.css(opacity: "", display: "")
                    $review_content.css(height: "").removeClass("expanding")
                }
              ), 1
            $review_content.off e

        $review_content.data("ready", false)
        $review_content_expanded = $(".review-content.expanded")
        if !auto_collapse || $review_content_expanded.length == 0
          $review_content.data("ready", true)
          $review_content.trigger("review_content:loaded")
        else
          # expand된 것이 있으면 우선 줄인다.
          collapse $review_content_expanded, ->
            # 줄이고 나서 늘이기 시작
            $review_content.data("ready", true)
            $review_content.trigger("review_content:loaded")

        if !$review.data("requested")
          $review.data("requested", true)
          $.getScript($review.data("expand-url"))
      else if $review_content.data("toggle")
        collapse $review_content


  handle_show_full_reviews: ($link) ->
    $link.on "ajax:beforeSend", ->
      $review_content = $(this).closest(".review").find(".review-content")
      if $review_content.hasClass("review-content-expanded")
        lib.animation.height_down $review_content, ->
          $review_content.removeClass("review-content-expanded")
        false
      else
        $review_content.bind "review_content:loaded", (e) ->
          if $review_content.hasClass("review-content-filled") && $review_content.hasClass("review-content-expanded")
            lib.animation.height_up $review_content
            $review_content.unbind e

        $review_content_expanded = $(".review-content-expanded")
        if $review_content_expanded.length > 0
          lib.animation.height_down $review_content_expanded, ->
            $review_content_expanded.removeClass("review-content-expanded")
            $review_content.addClass("review-content-expanded").trigger("review_content:loaded")
        else
          $review_content.addClass("review-content-expanded").trigger("review_content:loaded")

        !$review_content.hasClass("review-content-filled")

  review_popup_loader: ($image_area) ->
    $image = $image_area.find("img.review-image")
    $image_container = $image_area.find(".thumbnail-container")
    if $image_container.length > 0
      image_width = $image_container.width()
      image_height = $image_container.height()
    else
      image_width = $image.width()
      image_height = $image.height()
    $loader = $("<div id='review-popup-loader'></div>").css
      top: $image.offset().top
      left: $image.offset().left
      width: 1
      height: image_height
      backgroundColor: '#ccdede'
      position: 'absolute'
    $("body").append($loader)
    $loader.animate({
      width: image_width
    }, 280, lib.animation.ease_out)
    setTimeout (->
      $loader.animate({
        opacity: 0
      }, 280, lib.animation.ease_out)
      setTimeout (->
        $loader.remove()
      ), 280
    ), 1200

app.reviews = new Reviews

image_field_validate = ($input_field) ->
  if !lib.browser.supports_file_reader()
    if $input_field[0] && $input_field[0].value.match(/.png|.jpg|.jpeg|.gif|.bmp/i)
      is_image_file = true
    else
      is_image_file = false
  else
    $input = $input_field[0]
    if $input.files && $input.files[0] && !$input.files[0].type.match(/image/)
      is_image_file = false
    else
      is_image_file = true

  if is_image_file
    return true
  else
    alert("이미지 형식을 선택해주세요!")
    return false

window.ClientSideValidations.validators.local["review_message"] = (element, options) ->
  message = element.val()
  if !message || message == element.closest("form").data("review-message-default")
    return options.message

add_score = ($review, delta_score, delta_total) ->
  $score = $review.find(".like-score-container .like-score")
  score = parseInt $score.text().replace(/\+\-/, "")
  score += delta_score
  if score > 0
    $score.text("+" + score)
  else if score < 0
    $score.text(score)
  else
    $score.text("0")

  $total = $review.find("strong.total")
  $total.text(parseInt($total.text()) + delta_total) if delta_total != 0

  if delta_total >= 0 && delta_score > 0
    $plus = $review.find("strong.plus")
    $plus.text(parseInt($plus.text()) + 1)
  else if delta_total <= 0 && delta_score < 0
    $plus = $review.find("strong.plus")
    $plus.text(parseInt($plus.text()) - 1)

$(document).on "click", "a.link-like", ->
  $like_action = $(this).closest(".like-action")
  liked = $like_action.hasClass("liked")
  unliked = $like_action.hasClass("unliked")
  if liked
    $like_action.removeClass("liked")
    final_score = 0
    delta_score = -1
    delta_total = -1
  else
    $like_action.addClass("liked")
    final_score = 1
    if unliked
      $like_action.removeClass("unliked")
      delta_score = 2
      delta_total = 0
    else
      delta_score = 1
      delta_total = 1

  add_score $like_action.closest(".review"), delta_score, delta_total
  $.ajax({
    url: $like_action.data("url"),
    type: "post",
    data: {score: final_score}
  })

$(document).on "click", "a.link-unlike", ->
  $like_action = $(this).closest(".like-action")
  liked = $like_action.hasClass("liked")
  unliked = $like_action.hasClass("unliked")
  if unliked
    $like_action.removeClass("unliked")
    final_score = 0
    delta_score = 1
    delta_total = -1
  else
    $like_action.addClass("unliked")
    final_score = -1
    if liked
      $like_action.removeClass("liked")
      delta_score = -2
      delta_total = 0
    else
      delta_score = -1
      delta_total = 1

  add_score $like_action.closest(".review"), delta_score, delta_total
  $.ajax({
    url: $like_action.data("url"),
    type: "post",
    data: {score: final_score}
  })

$(document).on "change", "input.input-file.one-image", ->
  if !image_field_validate($(this))
    return

  $input = $(this)[0]
  $preview_container = $(this).siblings(".preview-container")
  $preview = $preview_container.find("img.preview")
  if !lib.browser.supports_file_reader()
    if this.value
      $(this).siblings().find(".description").html(this.value.match(/[^\\]*\.(\w+)$/)[0])
  else
    if $input.files && $input.files[0]
      $(this).siblings().find(".description").html($input.files[0].name)

$(document).on "change", "select.select-rating", ->
  $this = $(this)
  if $this.val() == ""
    rating = 5
  else
    rating = parseInt($this.val())

  $stars = $this.closest(".score-container").find(".star-rating-container i")
  $stars.each (i) ->
    if i < rating
      $(this).removeClass("star-empty")
    else
      $(this).addClass("star-empty")

$(document).on "change", "select#category", ->
  $.getScript($(this).val())

$(document).on "change", "select#sort_type", ->
  $.getScript($(this).val())

$(document).on "click", ".comments-link-collapse", ->
  if $(this).hasClass("selected")
    $(this).removeClass("selected")
    $(this).html "댓글 보기"
    $(this).closest(".actions-container").siblings(".comments-wrap").slideUp()
  else
    $(this).addClass("selected")
    $(this).html "댓글 접기"
    $(this).closest(".actions-container").siblings(".comments-wrap").slideDown()

format_select_rating = (item) ->
  result = "<div class='item'>"
  score = if item.id then parseInt(item.id) else 0
  for i in [0...score] by 1
    result += "<span class='star'></span>"

  for i in [score...5] by 1
    result += "<span class='star star-empty'></span>"

  result += "<span class='text'>" + item.text + "</span>"
  result += "</div>"

$(document).on "history:updated", (e, elements) ->
  $(elements).find("select.select-rating").each (i, e) ->
    app.form.select($(e), {
      formatResult: format_select_rating,
      formatSelection: format_select_rating,
      escapeMarkup: (m) -> m
      })

$(document).on "click", ".photo-review-popup", ->
  app.window.photo_review_popup $(this).data("photo-review-popup-url")
  app.reviews.review_popup_loader $(this)

$(document).on "click", ".delete-review, .edit-review, .new_review, .review-edit-close", ->
  $old_form = $("#review-edit-form");
  if $old_form.length > 0
    if !$(this).hasClass("delete-review") && !$(this).hasClass("edit-nonmember")
      $old_form.animate({
        opacity: 0
      }, 250, lib.animation.ease_in)
      setTimeout (->
        $old_form.remove()
      ), 250
    else
      $old_form.remove()

$(document).on "click", ".edit-nonmember", ->
  $action = $(this).data("action")
  if $action == "delete"
    action = "삭제 됩니다."
    type = "DELETE"
  else if $action == "edit"
    action = "수정할 수 있습니다."
    type = "POST"
  password = prompt "작성시 입력한 비밀번호를 입력하시면 " + action
  if password != null && password != ""
    $.ajax({
      url: $(this).data("path"),
      type: type,
      data: {password: password}
    })

$(document).on "click", ".field-box.add-image-container", ->
  app.review_image.add_image_container()

$(document).on "ajax:before", "form.form-review", (e) ->
  result = true
  $form = $(this)
  $form.find("input.review-option-field-value.required, select.review-option-field-value.required").each ->
    $input = $(this)
    if !$input.val()
      alert($input.data("message"))
      e.stopImmediatePropagation()
      result = false
      false

  if result
    $form.find("input.review-option-field-value-number").each ->
      $input = $(this)
      if !$input.val().match(/^[0-9]*$/)
        alert($input.data("message"))
        e.stopImmediatePropagation()
        result = false
        false

  result