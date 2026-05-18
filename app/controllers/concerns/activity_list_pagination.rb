module ActivityListPagination
  extend ActiveSupport::Concern

  PER_PAGE_CHOICES = [ 6, 12, 24, 48 ].freeze

  private

  def activity_list_per_page
    n = params[:per_page].to_i
    PER_PAGE_CHOICES.include?(n) ? n : 12
  end

  def activity_list_page_param(page_value, total_pages)
    p = page_value.to_i
    p = 1 if p < 1
    [ p, total_pages ].min
  end

  def paginate_activity_scope(scope, page_param:, per_page: nil)
    per_page = activity_list_per_page if per_page.nil?
    total = scope.count
    total_pages = total.zero? ? 1 : (total + per_page - 1) / per_page
    page = activity_list_page_param(params[page_param], total_pages)
    records = scope.offset((page - 1) * per_page).limit(per_page)

    pagination = {
      page: page,
      per_page: per_page,
      total: total,
      total_pages: total_pages,
      first_number: total.zero? ? 0 : (page - 1) * per_page + 1,
      last_number: (page - 1) * per_page + records.size,
      page_param: page_param
    }

    { records: records, pagination: pagination }
  end
end
