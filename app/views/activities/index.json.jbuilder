json.activities do
  json.array! @activities, partial: "activities/activity", as: :activity
end
json.pagination do
  json.page @pagination[:page]
  json.per_page @pagination[:per_page]
  json.total @pagination[:total]
  json.total_pages @pagination[:total_pages]
end
