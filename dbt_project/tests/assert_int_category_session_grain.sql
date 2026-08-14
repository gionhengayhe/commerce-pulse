select session_id, category
from {{ ref('int_category_session') }}
group by session_id, category
having count(*) > 1
