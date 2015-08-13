//= require jquery
//= require jquery-migrate
//= require autogrow
//= require jquery-ui
//= require jquery_ujs
//= require react
//= require react_ujs

//= require jquery-ui/datepicker
//= require jquery-ui-timepicker-addon
//= require jquery-ui/autocomplete
//= require jquery-ui/sortable
//= require bootstrap/tab
//= require bootstrap-colorpicker
//= require bootstrap/dropdown
//= require bootstrap/collapse
//= require bootstrap/modal

//= require cocoon
//= require pig/pig_config
//= require pig/widgets
//= require pig/navigation_manager
//= require pig/custom
//= require pig/character_limits
//= require pig/tabs
//= require pig/search_manager
//= require underscore
//= require sir-trevor
//= require redactor
//= require pig/user_filter
//= require_tree ./sir_trevor_custom_blocks
//= require pig/autocomplete-field
//= require select2
//= require pig/unsaved-changes
//= require_tree ./redactor_plugins
//= require_tree ./components

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
$(document).ready(function() {
  var $select2;
  $('input,textarea,select').focusin(function() {
    return $(this).parents('.form-group').addClass('focus');
  });
  $('input,textarea,select').focusout(function() {
    return $(this).parents('.form-group').removeClass('focus');
  });
  $select2 = $('.select2');
  $select2.select2({
    tags: true
  });
  return $.ui.autocomplete.prototype._resizeMenu = function() {
    var ul;
    ul = this.menu.element;
    ul.outerWidth(this.element.outerWidth());
  };
});
window.Pig = {
  ContentPackages: {
    initForm: function() {
      $('#content_package_content_type_id').change(function() {
        return Pig.ContentPackages.updateGoal();
      });
      $('#content_package_notes').change(function() {
        return Pig.ContentPackages.goalChangedByUser = true;
      });
      return Pig.ContentPackages.updateGoal();
    },
    updateGoal: function() {
      var goal;
      if (!Pig.ContentPackages.goalChangedByUser) {
        goal = Pig.ContentPackages.descriptions[$('#content_package_content_type_id').val()];
        return $('#content_package_notes').val(goal);
      }
    },
    goalChangedByUser: false
  },
  ContentTypes: {
    init: function() {
      $('.sitemap').on('click', 'td.td-name', function() {
        var content_type_id, depth, link, row, _results, _results2;
        link = $(this);
        row = link.parent();
        if ($(this).data('open') === 1) {
          link.data('open', 0);
          link.find('i.sitemap-caret').removeClass('fa-caret-down').addClass('fa-caret-right');
          depth = row.data('depth');
          _results = [];
          while (true) {
            row = row.next();
            if (row.data('depth') > depth) {
              row.hide();
              link = row.find('td.td-name');
              link.data('open', 0);
              link.find('i.sitemap-caret').removeClass('fa-caret-down').addClass('fa-caret-right');
            } else {
              break;
            }
          }
          return _results;
        } else if ($(this).data('loaded') === 1) {
          link.data('open', 1);
          link.find('i.sitemap-caret').removeClass('fa-caret-right').addClass('fa-caret-down');
          depth = row.data('depth');
          _results2 = [];
          while (true) {
            row = row.next();
            if (row.data('depth') != null) {
              if (row.data('depth') === (depth + 1)) {
                row.show();
              } else if (row.data('depth') === depth) {
                break;
              }
            } else {
              break;
            }
          }
          return _results2;
        } else {
          content_type_id = row.attr('id').split('-').slice(-1)[0];
          link.data('loaded', 0);
          setTimeout("Pig.ContentTypes.loading(" + content_type_id + ")", 250);
          return $.get(row.data('open-url')).success(function() {
            link.data('loaded', 1);
            link.data('open', 1);
            link.find('i.sitemap-caret').removeClass('fa-spin').removeClass('fa-spinner').removeClass('fa-caret-right');
            return link.find('i.sitemap-caret').addClass('fa-caret-down');
          });
        }
      });
      $('.js-duplicate-link').on('click', function() {
        Pig.ContentTypes.seedId = $(this).data('content-type-id');
        return $('#duplicate-modal').modal();
      });
      return $('.js-duplicate-submit').on('click', function(event) {
        var duplicateTo, path;
        path = $(event.currentTarget).data('duplicate-url').replace(':id', Pig.ContentTypes.seedId)
        duplicateTo = $('#duplicate_to').val();
        if (duplicateTo !== "") {
          path += "?to=" + duplicateTo;
        }
        return window.location = path;
      });
    },
    loading: function(id) {
      var link;
      link = $("#content-type-" + id + " td.td-name");
      if (link.data('loaded') === 0) {
        return link.find('i.sitemap-caret').removeClass('fa-caret-right').addClass('fa-spinner').addClass('fa-spin');
      }
    }
  },
  Redactor: {
    init: function() {
     $('.redactor textarea').redactor({
        removeClasses: true,
        removeStyles: true,
        buttons: ['unorderedlist', 'orderedlist', 'link', 'html'],
        convertDivs: true,
        path: 'vendor/assets/javascripts/redactor',
        plugins: $('.redactor textarea').data('redactor-plugins'),
        tabKey: false,
        focusCallback: function(e) {
          return $(e.currentTarget).parents(".form-group").addClass("focus");
        },
        blurCallback: function(e) {
          return $(e.currentTarget).parents(".form-group").removeClass("focus");
        },
        initCallback: function(e) {
          if (CharacterLimits && this.$element.data('limit-quantity')) {
            return CharacterLimits.registerRedactor(this);
          }
        },
        changeCallback: function(e) {
          if (CharacterLimits && this.$element.data('limit-quantity')) {
            return CharacterLimits.redactorChanged(this);
          }
        }
      });

      $('.rich_redactor textarea').redactor({
        buttons: ['html', 'formatting', 'bold', 'italic', 'unorderedlist', 'orderedlist', 'image', 'link', 'horizontalrule'],
        plugins: $('.rich_redactor textarea').data('redactor-plugins'),
        path: 'vendor/assets/javascripts/redactor',
        imageUpload: PigConfig.namespace + 'redactor_image_uploads?file_type=image',
        imageGetJson: PigConfig.namespace + 'redactor_image_uploads',
        formatting: ['p', 'h1', 'h2', 'h3', 'h4', 'h5'],
        imageResizable: false,
        imagePosition: false,
        tabKey: false,
        cleanStyleOnEnter: true,
        focusCallback: function(e) {
          return $(e.currentTarget).parents(".form-group").addClass("focus");
        },
        blurCallback: function(e) {
          return $(e.currentTarget).parents(".form-group").removeClass("focus");
        },
        initCallback: function(e) {
          redactorPluginUpdates.update();
        },
        changeCallback: function(e) {
          redactorPluginUpdates.update('change');
        }
      });
    }
  },
  Sitemap: {
    init: function() {
      Pig.Sitemap.filter();
      $('select#status').change(function() {
        return Pig.Sitemap.filter();
      });
      return $('#sitemap').on('click', '.has-children td.td-name', function(e) {
        var content_package_id, depth, link, row, _results, _results2;
        link = $(this);
        row = link.parent();
        if ($(this).attr('data-open') === '1') {
          link.attr('data-open', 0);
          link.find('i.sitemap-caret').removeClass('fa-caret-down').addClass('fa-caret-right');
          depth = row.data('depth');
          _results = [];
          while (true) {
            row = row.next();
            if (row.data('depth') > depth) {
              row.hide();
              link = row.find('td.td-name');
              link.attr('data-open', 0);
              link.find('i.sitemap-caret').removeClass('fa-caret-down').addClass('fa-caret-right');
            } else {
              break;
            }
          }
          if (e.originalEvent !== undefined)
            Pig.Sitemap.setCookie();
          return _results;
        } else if ($(this).data('loaded') === 1) {
          link.attr('data-open', 1);
          link.find('i.sitemap-caret').removeClass('fa-caret-right').addClass('fa-caret-down');
          depth = row.data('depth');
          _results2 = [];
          while (true) {
            row = row.next();
            if (row.data('depth') != null) {
              if (row.data('depth') === (depth + 1)) {
                row.show();
              } else if (row.data('depth') === depth) {
                break;
              }
            } else {
              break;
            }
          }
          if (e.originalEvent !== undefined)
            Pig.Sitemap.setCookie();
          return _results2;
        } else {
          content_package_id = row.attr('id').split('-').slice(-1)[0];
          link.attr('data-loaded', 0);
          setTimeout("Pig.Sitemap.loading(" + content_package_id + ")", 250);
          return $.get(row.data('children-url'), function() {
            link.attr('data-loaded', 1);
            // link.data('open', 1);
            link.attr('data-open', 1);
            link.find('i.sitemap-caret').removeClass('fa-spin').removeClass('fa-spinner').removeClass('fa-caret-right');
            if (e.originalEvent !== undefined)
              Pig.Sitemap.setCookie();
            return link.find('i.sitemap-caret').addClass('fa-caret-down');
          });
        }
      });
    },
    filter: function() {
      var status;
      status = $('select#status').val();
      if (status.length > 0) {
        $('h1').text("Content list - " + ($('select#status option:selected').text()));
        $("#sitemap tr.content-package").hide();
        return $("#sitemap tr.status-" + status).show();
      } else {
        $('h1').text('Content list');
        return $("#sitemap tr.content-package").show();
      }
    },
    loading: function(id) {
      var link;
      link = $("#content-package-" + id + " td.td-name");
      if (link.attr('data-loaded') === '0') {
        return link.find('i.sitemap-caret').removeClass('fa-caret-right').addClass('fa-spinner').addClass('fa-spin');
      }
    },
    getCookie: function() {
      var value = "; " + document.cookie;
      var parts = value.split("; " + "open" + "=");
      cookie = parts.length == 2 ? JSON.parse(parts.pop().split(";").shift()) : [];
      return cookie;
    },
    setCookie: function() {
      document.cookie = "open=" + JSON.stringify(Pig.Sitemap.getOpenNodes());
    },
    addToCookie: function(cp_id) {
      var cookie = Pig.Sitemap.getCookie();
      cookie.push(cp_id);
      document.cookie = "open=" + JSON.stringify(cookie);
    },
    getOpenNodes: function() {
      return $.map($('.td-name[data-open=1]'), function(a) {
        return $(a).data('content-package');
      });
    },
    setOpenNodes: function() {
      $.each(Pig.Sitemap.getCookie(), function(i, v) {
        $('.td-name[data-content-package="'+ v +'"]').each(function() {
          $(this).trigger('click');
        });
      });
    },
    openChildNodes: function(children_ids) {
      var cookie = Pig.Sitemap.getCookie();
      $.each(cookie, function(i, v){
        if (children_ids.indexOf(v) !== -1) {
          $('.td-name[data-content-package="'+ v +'"]').each(function() {
            $(this).trigger('click');
          });
        }
      });
    }
  },
  Sortable: {
    init: function() {
      $('.sortable').sortable({
        placeholder: 'well well-placeholder',
        containment: 'parent'
      });
      return $('a.sortable-submit').click(function(event) {
        var url;
        url = $(this).attr('href') + '?';
        url += $('.sortable').sortable("serialize");
        return $(this).attr('href', url);
      });
    }
  }
};
window.YmAssets = {
  addDefaults: function(options, defaultOptions) {
    if (typeof options === 'object') {
      return $.extend(defaultOptions, options);
    } else {
      return defaultOptions;
    }
  },
  scrollTo: function(elem, options) {
    elem = $(elem);
    if (elem.length) {
      options = YmAssets.addDefaults(options, {
        offset: 0,
        duration: 750
      });
      return $('html, body').stop().animate({
        scrollTop: elem.position().top - options.offset
      }, options.duration);
    }
  },
  Tabs: {
    init: function() {
      var target_tab_link;
      if (window.location.hash) {
        target_tab_link = $(".nav-tabs li a[href='" + window.location.hash + "']").first();
        if (target_tab_link.length) {
          target_tab_link.tab('show');
        }
      }
      return $('.tab-pane').has('input.error, .control-group.error').each(__bind(function(idx, pane) {
        var link;
        link = $(".tabbable .nav a[href='#" + ($(pane).attr('id')) + "']");
        link.parent().addClass('error');
        if (idx === 0) {
          return link.tab('show');
        }
      }, this));
    }
  },
  Bootstrap: {
    init: function() {
      return $("[data-toggle='modal'][data-modal-url]").on('click', function() {
        var new_modal;
        $('.temp-modal').modal('hide');
        new_modal = $("<div class='modal temp-modal'></div>");
        if ($(this).data('modal-id') !== void 0) {
          new_modal.attr('id', $(this).data('modal-id'));
        }
        new_modal.modal({
          backdrop: $(this).data('backdrop')
        });
        new_modal.load($(this).data('modal-url'));
        return new_modal.on('hidden', function() {
          return $(this).remove();
        });
      });
    }
  },
  Forms: {
    initColorPickers: function() {
      return $('.colorpicker-control input').colorpicker().on('changeColor', function(colorpicker) {
        var colorDisplay;
        colorDisplay = $(this).parents('.colorpicker-control').find('.add-on i');
        return colorDisplay.css('background-color', colorpicker.color.toHex());
      });
    },
    initDatepickers: function() {
      $('input.datepicker').datepicker({
        dateFormat: 'dd/mm/yy'
      });
      $('input.datetime').datetimepicker({
        dateFormat: 'dd/mm/yy',
        timeFormat: 'hh:mm'
      });
      return $('input.timepicker').timepicker({
        timeFormat: 'hh:mm',
        stepMinute: 5
      });
    },
    LoadingText: {
      add: function(elem) {
        var btn, clickedBtn, loadingText, submitBtn, submitBtns;
        submitBtns = elem.find("input[type='submit']");
        submitBtns.addClass('disabled');
        clickedBtn = elem.find("input[type='submit'][data-clicked='true']");
        if (clickedBtn.length) {
          submitBtn = clickedBtn;
        } else {
          if (submitBtns.length > 1) {
            submitBtn = $(((function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = submitBtns.length; _i < _len; _i++) {
                btn = submitBtns[_i];
                if ($(btn).data('primary') === true) {
                  _results.push(btn);
                }
              }
              return _results;
            })())[0]);
          } else {
            submitBtn = $(submitBtns[0]);
          }
        }
        if (submitBtn != null) {
          loadingText = submitBtn.data("loading-text") || 'Saving...';
          return submitBtn.attr('data-non-loading-text', submitBtn.val()).val(loadingText);
        }
      },
      remove: function(elem) {
        var submitBtn;
        submitBtn = elem.find("input[type='submit']");
        return submitBtn.removeClass('disabled').val(submitBtn.data('non-loading-text'));
      },
      init: function() {
        $(".formtastic input[type='submit']").on("click", function(event) {
          return $(this).attr('data-clicked', true);
        });
        $(".formtastic:not('.loading-text-disabled')").on("submit", function() {
          return YmAssets.Forms.LoadingText.add($(this));
        });
        if (typeof ClientSideValidations !== 'undefined') {
          return ClientSideValidations.callbacks.form.fail = function(element, message, callback) {
            return YmAssets.Forms.LoadingText.remove(element);
          };
        }
      }
    },
    init: function() {
      YmAssets.Forms.LoadingText.init();
      YmAssets.Forms.initDatepickers();
      YmAssets.Forms.initColorPickers();
      return $('textarea:not(.redactor):not([data-dont-grow=true])').autogrow();
    }
  },
  Modals: {
    initAutoModal: function() {
      var new_href, res, search_params;
      $('#flash-modal').modal('show');
      if (res = window.location.search.match(/modal=(\w+)/)) {
        if ($("#" + res[1]).length) {
          $("#" + res[1]).modal('show');
          search_params = window.location.search.replace('?', '').split('&');
          search_params.splice($.inArray("modal=" + res[1], search_params), 1);
          if (search_params.length > 0) {
            search_params = "?" + (search_params.join('&'));
          } else {
            search_params = "";
          }
          new_href = "" + window.location.origin + window.location.pathname + search_params;
          if (history.pushState !== void 0) {
            return history.pushState({
              path: this.path
            }, '', new_href);
          }
        }
      }
    }
  },
  ReadMoreTruncate: {
    init: function() {
      return $('.read-more-link').on('click', function(event) {
        var wrapper;
        event.preventDefault();
        wrapper = $(this).parents('.read-more-wrapper:first');
        wrapper.children('.read-more-trunc').hide();
        return wrapper.children('.read-more-full').show();
      });
    }
  },
  init: function() {
    YmAssets.Tabs.init();
    YmAssets.Bootstrap.init();
    YmAssets.Forms.init();
    YmAssets.Modals.initAutoModal();
    return YmAssets.ReadMoreTruncate.init();
  }
};
$(document).ready(function() {
  return YmAssets.init();
});
