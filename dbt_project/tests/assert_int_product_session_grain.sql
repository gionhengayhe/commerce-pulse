select session_id, product_id
from {{ ref('int_product_session') }}
group by session_id, product_id
having count(*) > 1
