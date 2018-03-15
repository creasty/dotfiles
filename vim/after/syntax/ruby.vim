"  General
"-----------------------------------------------
syn keyword rubyAttribute class_attribute
syn keyword rubyAttribute attr_internal attr_internal_accessor attr_internal_reader attr_internal_writer
syn keyword rubyAttribute cattr_accessor cattr_reader cattr_writer mattr_accessor mattr_reader mattr_writer
syn keyword rubyAttribute thread_cattr_accessor thread_cattr_reader thread_cattr_writer thread_mattr_accessor thread_mattr_reader thread_mattr_writer
syn keyword rubyMacro alias_attribute concern concerning delegate delegate_missing_to with_options

syn keyword rubyHelper logger

"  Mailer
"-----------------------------------------------
syn keyword rubyResponse mail render
syn match   rubyResponse "\<headers\>"
syn match   rubyHelper "\<headers\[\@="
syn keyword rubyHelper attachments
syn keyword rubyMacro default helper helper_attr helper_method layout

"  Model
"-----------------------------------------------
syn keyword rubyMacro accepts_nested_attributes_for attr_readonly attribute enum serialize store store_accessor
syn keyword rubyMacro default_scope scope
syn keyword rubyEntity belongs_to has_one composed_of
syn keyword rubyEntities has_many has_and_belongs_to_many
syn keyword rubyCallback before_validation after_validation
syn keyword rubyCallback before_create before_destroy before_save before_update
syn keyword rubyCallback  after_create  after_destroy  after_save  after_update
syn keyword rubyCallback around_create around_destroy around_save around_update
syn keyword rubyCallback after_commit after_create_commit after_update_commit after_destroy_commit after_rollback
syn keyword rubyCallback after_find after_initialize after_touch
syn keyword rubyMacro validates validate has_secure_password has_secure_token
syn keyword rubyMacro included class_methods

"  Controller
"-----------------------------------------------
syn keyword rubyHelper params request response session headers cookies flash render_to_string
syn keyword rubyMacro helper helper_attr helper_method filter layout serialize exempt_from_layout filter_parameter_logging hide_action cache_sweeper protect_from_forgery caches_page cache_page caches_action expire_page expire_action
syn keyword rubyExceptionHandler rescue_from
syn match   rubyMacro '\<respond_to\>\ze[( ] *[:*]'
syn match   rubyResponse '\<respond_to\>\ze[( ] *\%([&{]\|do\>\)'
syn keyword rubyResponse render head redirect_to redirect_back respond_with
syn keyword rubyCallback before_filter append_before_filter prepend_before_filter after_filter append_after_filter prepend_after_filter around_filter append_around_filter prepend_around_filter skip_before_filter skip_after_filter skip_filter before_action append_before_action prepend_before_action after_action append_after_action prepend_after_action around_action append_around_action prepend_around_action skip_before_action skip_after_action skip_action

"  Migration
"-----------------------------------------------
syn keyword rubySchema create_table change_table drop_table rename_table create_join_table drop_join_table
syn keyword rubySchema add_column rename_column change_column change_column_default change_column_null remove_column remove_columns
syn keyword rubySchema add_foreign_key remove_foreign_key
syn keyword rubySchema add_timestamps remove_timestamps
syn keyword rubySchema add_reference remove_reference add_belongs_to remove_belongs_to
syn keyword rubySchema add_index remove_index rename_index
syn keyword rubySchema enable_extension reversible revert
syn keyword rubySchema execute transaction


"  Spec
"-----------------------------------------------
syn keyword rubyTestMacro before after around background setup teardown
syn keyword rubyTestMacro context describe feature shared_context shared_examples shared_examples_for containedin=rubyKeywordAsMethod
syn keyword rubyTestMacro it example specify scenario include_examples include_context it_should_behave_like it_behaves_like
syn keyword rubyComment xcontext xdescribe xfeature containedin=rubyKeywordAsMethod
syn keyword rubyComment xit xexample xspecify xscenario
syn keyword rubyTestHelper request response flash session cookies fixture_file_upload
syn keyword rubyTestHelper body current_host current_path current_scope current_url current_window html response_headers source status_code title windows
syn keyword rubyTestHelper page text
syn keyword rubyTestHelper all field_labeled find find_all find_button find_by_id find_field find_link first
syn keyword rubyTestAction evaluate_script execute_script go_back go_forward open_new_window save_and_open_page save_and_open_screenshot save_page save_screenshot switch_to_frame switch_to_window visit window_opened_by within within_element within_fieldset within_frame within_table within_window
syn keyword rubyTestAction attach_file check choose click_button click_link click_link_or_button click_on fill_in select uncheck unselect

"  Highlights
"-----------------------------------------------
hi def link rubyEntity           rubyMacro
hi def link rubyEntities         rubyMacro
hi def link rubyExceptionHandler rubyMacro
hi def link rubyCallback         rubyMacro
hi def link rubyTestMacro        rubyMacro
hi def link rubyMacro            Function
hi def link rubySchema           rubyControl
hi def link rubyResponse         rubyControl
hi def link rubyTestHelper       rubyHelper
hi def link rubyTestAction       rubyControl
hi def link rubyHelper           Function
