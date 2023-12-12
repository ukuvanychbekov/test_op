module OpenProject::XlsExport::Hooks
  class WorkPackageHook < OpenProject::Hook::ViewListener
    def link_to_xls(context, label, options = {})
      url = {
        project_id: context[:project],
        format: "xls"
      }

      context[:link_formatter].link_to label, url: url.merge(options)
    end
  end
end
