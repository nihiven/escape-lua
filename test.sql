select
	c.conversation_id,
	i.*
from
	conversations c
inner join
	conversation_items i
	 on c.converation_id = i.conversation_id
where
	i.item_id in (	select
										top 2
										i2.item_id
									from
										conversation_items i2
									where
										i2.conversation_id = i.conversation_id
									order by
										created_at desc)