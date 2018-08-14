---


---

<hr>
<p>title: Redis常用命令<br>
date: 2018-08-11 13:00:36<br>
tags:<br>
-redis<br>
categories:<br>
-redis</p>
<hr>
<h3 id="string">1 STRING</h3>
<p>Redis的字符串是一个由字节组成的序列，可以存储3种类型的值：<strong>字节串，整数，浮点数。</strong></p>

<table>
<thead>
<tr>
<th>命令</th>
<th>用例和描述</th>
</tr>
</thead>
<tbody>
<tr>
<td>GET</td>
<td><code>GET key-name</code> 获取健值</td>
</tr>
<tr>
<td>SET</td>
<td><code>SET key-name</code> 设置健值</td>
</tr>
<tr>
<td>DEL</td>
<td><code>DEL key-name</code> 删除健</td>
</tr>
<tr>
<td>INCR</td>
<td><code>INCR key-name</code> 将键值加1</td>
</tr>
<tr>
<td>DECR</td>
<td><code>DECR key-name</code> 将键值减1</td>
</tr>
<tr>
<td>INCRBY</td>
<td><code>INCRBY key-name amount</code> 将健值加上amount</td>
</tr>
<tr>
<td>DECRBY</td>
<td><code>DECRBY key-name amount</code> 将健值减上amount</td>
</tr>
<tr>
<td>INCRBYFLOAT</td>
<td><code>INCRBYFLOAT key-name amount</code> 将健值减上浮点数amount</td>
</tr>
<tr>
<td>APPEND</td>
<td><code>APPEND key-name value</code> 将值value追加到key-name的末尾</td>
</tr>
<tr>
<td>GETRANGE</td>
<td><code>GETRANGE key-name start end</code> 获取偏移量start至end范围的子串，包括start和end在内</td>
</tr>
<tr>
<td>SETRANGE</td>
<td><code>SETRANGE key-name offset value</code> 将从start开始的子串设置为value</td>
</tr>
<tr>
<td>GETBIT</td>
<td><code>GETBIT key-name offset</code> 将字符串看到二进制位串，返回偏移量为offset的值</td>
</tr>
<tr>
<td>SETBIT</td>
<td><code>SETBIT key-name offset value</code> 将字符串看到二进制位串，将偏移量为offset的值设置为value</td>
</tr>
<tr>
<td>BITCOUNT</td>
<td><code>BITCOUNT key-name [start,end]</code> 统计比特位值为1的数量</td>
</tr>
<tr>
<td>BITOP</td>
<td><code>BITOP operation dest-key key-name [key-name ...]</code>对一个或多个二进制位串执行包括 <strong>并（AND）</strong>、<strong>或（OR）</strong>、<strong>异或（XOR</strong>）、**非（NOT）**在内的任意一种按位运算操作，并将结果保存在dest_key键里面</td>
</tr>
</tbody>
</table><ul>
<li>对于一个保存了空串或不存在的健进行自增自减速，Redis会将健当成0来处理。如果对一个值无法被解释为整数或者浮点数的健进行自增自减操作，Redis会返回一个错误。</li>
<li>如果使用setrangea或者SETBIT写入的时候，字符串当前的长度不能满足，那么Redis会自动地使用空字节（null）来填充，然后再执行写入操作</li>
</ul>
<h3 id="list">2 LIST</h3>

<table>
<thead>
<tr>
<th>命令</th>
<th>用例和描述</th>
</tr>
</thead>
<tbody>
<tr>
<td>RPUSH</td>
<td><code>RPUSH key-name value [value ...]</code> 将一个或多个值推入列表的右端</td>
</tr>
<tr>
<td>LPUSH</td>
<td><code>LPUSH key-name value [value ...]</code> 将一个或多个值推入列表的左端</td>
</tr>
<tr>
<td>RPOP</td>
<td><code>RPOP key-name</code> 移除并返回列表最右端的元素</td>
</tr>
<tr>
<td>LPOP</td>
<td><code>RPOP key-name</code> 移除并返回列表最左端的元素</td>
</tr>
<tr>
<td>LINDEX</td>
<td><code>LINDEX key-name offset</code> 返回列表中偏移量为offset的元素</td>
</tr>
<tr>
<td>LRANGE</td>
<td><code>LRANGE key-name start end</code> 返回start到end（包括start和end）偏移量范围内的所有元素</td>
</tr>
<tr>
<td>LTRIM</td>
<td><code>LTRIM key-name start end</code> 对列表进行修剪，只保留start至end范围的元素，包括start和end在内</td>
</tr>
<tr>
<td>BLPOP</td>
<td><code>BLPOP key-name [key-name ...] timeout</code> 从第一个非空列表中弹出位于最左端的元素，或者在timeout秒之内阻塞并等待可弹出的元素出现</td>
</tr>
<tr>
<td>BRPOP</td>
<td><code>BRPOP key-name [key-name ...] timeout</code> 从第一个非空列表中弹出位于最右端的元素，或者在timeout秒之内阻塞并等待可弹出的元素出现</td>
</tr>
<tr>
<td>RPOPLPUSH</td>
<td><code>RPOPLPUSH source-key dest-key</code> 从source-key列表中弹出位于最右边端的元素，然后将这个元素推入到dest-key的最左端，并向用户返回这个元素</td>
</tr>
<tr>
<td>BRPOPLPUSH</td>
<td><code>BRPOPLPUSH source-key dest-key</code> 从source-key列表中弹出位于最右边端的元素，然后将这个元素推入到dest-key的最左端，并向用户返回这个元素。如果source-key为空，那么在timeout秒之内阻塞并等待可弹出的元素出现</td>
</tr>
</tbody>
</table><h3 id="set">3 SET</h3>

<table>
<thead>
<tr>
<th>命令</th>
<th>用例和描述</th>
</tr>
</thead>
<tbody>
<tr>
<td>SADD</td>
<td><code>SADD key-name item [item ...]</code> 将一个或多个元素添加到集合，并返回被添加元素当中原本不存在于集合里面的元素数量</td>
</tr>
<tr>
<td>SREM</td>
<td><code>SREM key-name item [item ...]</code> 从集合里面移除一个或多个元素，并返回移除的数量</td>
</tr>
<tr>
<td>SISMEMBER</td>
<td><code>SISMEMBEER key-name item</code> 检查元素是否在于集合中</td>
</tr>
<tr>
<td>SCARD</td>
<td><code>SCARD key-name</code> 返回集合中元素的数量</td>
</tr>
<tr>
<td>SMEMBERS</td>
<td><code>SMEMBERS key-name</code> 返回所有的元素</td>
</tr>
<tr>
<td>SRANDMEMBER</td>
<td><code>SRANDMEMBER key-name [count]</code> 随机返回一个或多个元素。当count为正整数时，命令返回的元素不会重复。当count为负数时，命令返回的随机元素可能会出现重复</td>
</tr>
<tr>
<td>SPOP</td>
<td><code>SPOP key-name</code> 随机移除集合中的一个元素，并返回移除的元素</td>
</tr>
<tr>
<td>SMOVE</td>
<td><code>SMOVE source-key dest-key item</code> 如果source-key包含元素item,那么从source-key里面移除该元素，并将该元素添加到dest-key集合中。成功返回1，否则为0</td>
</tr>
<tr>
<td>SDIFF</td>
<td><code>SDIFF key-name [key-name ...]</code> 返回那些存在于第一个集合，不存在于其它集合中的元素</td>
</tr>
<tr>
<td>SDIFFSTORE</td>
<td><code>SDIFFSTORE dest-key key-name [key-name ...]</code> 将那些在于第一个集合，不存在于其它集合中的元素存储到dest-key集合里面</td>
</tr>
<tr>
<td>SINTER</td>
<td><code>SINTER key-name [key-name ...]</code> 返回同时存在于所有集合中的元素</td>
</tr>
<tr>
<td>SINTERSTORE</td>
<td><code>SINTERSTORE dest-key key-name [key-name ...]</code> 将同时存在于所有集合中的元素放到dest-key集合里面</td>
</tr>
<tr>
<td>SUNION</td>
<td><code>SUNION key-name [key-name ...]</code> 返回那些至少存在于一个集合中的元素</td>
</tr>
<tr>
<td>SUNIONSTORE</td>
<td><code>SUNIONSTORE dest-key key-name [key-name ...]</code> 将那些至少存在于一个集合中的元素放到dest-key集合里面</td>
</tr>
</tbody>
</table><h3 id="hash">4 HASH</h3>

<table>
<thead>
<tr>
<th>命令</th>
<th>用例和描述</th>
</tr>
</thead>
<tbody>
<tr>
<td>HGET</td>
<td><code>HMGET key-name key</code> 获取一个健的值</td>
</tr>
<tr>
<td>HSET</td>
<td><code>HMSET key-name key value</code> 为散列里面的一个健设置值</td>
</tr>
<tr>
<td>HGETAL</td>
<td><code>HGETALL key-name</code> 获取所有的健值对</td>
</tr>
<tr>
<td>HMGET</td>
<td><code>HMGET key-name key [key...]</code> 从散列里面获取一个或多个健的值</td>
</tr>
<tr>
<td>HMSET</td>
<td><code>HMSET key-name key value [key value...]</code> 为散列里面的一个或多个健设置值</td>
</tr>
<tr>
<td>HDEL</td>
<td><code>HDEL key-name key [key ...]</code> 删除一个或多个健，并返回成功的数量</td>
</tr>
<tr>
<td>HLEN</td>
<td><code>HLEN key-name</code> 返回散列里包含的健值对数量</td>
</tr>
<tr>
<td>SMEMBERS</td>
<td><code>SMEMBERS key-name</code> 返回所有的元素</td>
</tr>
<tr>
<td>HEXIST</td>
<td><code>HEXIST key-name key</code> 检查给定的健是否存在</td>
</tr>
<tr>
<td>HKEYS</td>
<td><code>HKEYS key-name</code> 获取所有的健</td>
</tr>
<tr>
<td>HVALS</td>
<td><code>HVALS key-name</code> 获取所有的值</td>
</tr>
<tr>
<td>HINCRBY</td>
<td><code>HINCRBY key-name key increment</code> 自增加整数increment</td>
</tr>
<tr>
<td>HINCRBYFLOAT</td>
<td><code>HINCRBYFLOAT key-name key increment</code> 自增加浮点数increment</td>
</tr>
</tbody>
</table><h3 id="zset">5 ZSET</h3>

<table>
<thead>
<tr>
<th>命令</th>
<th>用例和描述</th>
</tr>
</thead>
<tbody>
<tr>
<td>ZADD</td>
<td><code>ZADD key-name score member[score member ...]</code> 将带有指定分值的成员添加到集合里面</td>
</tr>
<tr>
<td>ZREM</td>
<td><code>ZREM key-name member [member...]</code> 从集合里面移除一个或多个成员，并返回移除的数量</td>
</tr>
<tr>
<td>ZCARD</td>
<td><code>ZCARD key-name</code> 返回集合中成员的数量</td>
</tr>
<tr>
<td>ZINCRBY</td>
<td><code>ZINCRBY key-name increment member</code> 给member的分值加上increment</td>
</tr>
<tr>
<td>ZCOUNT</td>
<td><code>ZOUNT key-name min max</code> 返回分值介于min和max之间的成员数</td>
</tr>
<tr>
<td>ZRANK</td>
<td><code>ZRANK key-name member</code> 返回member的排名</td>
</tr>
<tr>
<td>ZSCORE</td>
<td><code>ZSCORE key-name member</code> 返回member的分值</td>
</tr>
<tr>
<td>ZRANGE</td>
<td><code>ZRANGE key-name start stop [withscores]</code> 返回排名介于start和stop之间的成员，如果指定了withscores选项，那么把成员的分值也一并返回</td>
</tr>
<tr>
<td>ZREVRANK</td>
<td><code>ZREVRANK key-name member</code> 返回member的排名,按照分值从大小到排列</td>
</tr>
<tr>
<td>ZREVRANGE</td>
<td><code>ZREVRANGE key-name start stop [withscores]</code> 返回排名介于start和stop之间的成员，按照分值从大小到排列</td>
</tr>
<tr>
<td>ZRANGEBYSCORE</td>
<td><code>ZRANGEBYSCORE key-name min max [withscores] [limit offset count]</code> 返回分值介于min和max之间的成员</td>
</tr>
<tr>
<td>ZREVRANGEBYSCORE</td>
<td><code>ZREVRANGEBYSCORE key-name min max [withscores] [limit offset count]</code> 按照分值从大小到排列，返回分值介于min和max之间的成员,</td>
</tr>
<tr>
<td>ZREMRANGEBYRANK</td>
<td><code>ZREMRANGEBYRANK key-name start stop</code> 删除排名位于start和stop之间的所有成员</td>
</tr>
<tr>
<td>ZREMRANGEBYSCORE</td>
<td><code>ZREMRANGEBYSCORE key-name min max</code> 删除分值位于min和max之间的所有成员</td>
</tr>
<tr>
<td>ZINTERSTORE</td>
<td><code>ZINTERSTORE dest-key key-count key [key ...] [WEIGHTS weight [weight]] [AGGREGATE SUM|MIN|MAX]</code> 计算给定的一个或多个有序集的交集，其中给定 key 的数量必须以 key-count参数指定，并将该并集(结果集)储存到 dest-key。默认情况下，结果集中某个成员的 score 值是所有给定集下该成员 score 值之和</td>
</tr>
<tr>
<td>ZUNIONSTORE</td>
<td><code>ZUNIONSTORE dest-key key-count key [key ...] [WEIGHTS weight [weight]] [AGGREGATE SUM|MIN|MAX]</code> 计算给定的一个或多个有序集的并集，其中给定 key 的数量必须以 key-count参数指定，并将该并集(结果集)储存到 dest-key。默认情况下，结果集中某个成员的 score 值是所有给定集下该成员 score 值之和</td>
</tr>
</tbody>
</table><ul>
<li><code>WEIGHTS</code>  选项，你可以为  <em>每个</em>  给定有序集  <em>分别</em>  指定一个乘法因子(multiplication factor)，每个给定有序集的所有成员的  <code>score</code>  值在传递给聚合函数(aggregation function)之前都要先乘以该有序集的因子。如果没有指定  <code>WEIGHTS</code>  选项，乘法因子默认设置为  <code>1</code>  。</li>
<li><code>AGGREGATE</code> 选项，你可以指定并集的结果集的聚合方式。</li>
</ul>
<h3 id="pubsub">6 pub/sub</h3>

<table>
<thead>
<tr>
<th>命令</th>
<th>用例和描述</th>
</tr>
</thead>
<tbody>
<tr>
<td>SUBSCRIBE</td>
<td><code>SUBSCRIBE channel [channel ...]</code> 订阅给定的一个或多个频道</td>
</tr>
<tr>
<td>UNSUBSCRIBE</td>
<td><code>UNSUBSCRIBE [channel [channel ...]]</code> 退订给定的一个或多个频道,没有指定则退妯所有频道</td>
</tr>
<tr>
<td>PUBLISH</td>
<td><code>PUBLISH channel message</code> 向指定频道发送消息</td>
</tr>
<tr>
<td>PSUBSCRIBE</td>
<td><code>PSUBSCRIBE pattern [pattern ...]</code> 订阅与给定模式相匹配的所有频道</td>
</tr>
<tr>
<td>PUNSUBSCRIBE</td>
<td><code>PUNSUBSCRIBE [pattern [pattern ...][</code> 退订给定的模式,如果没有指定则退订所有模式</td>
</tr>
</tbody>
</table><ul>
<li>旧版Redis如果客户端读取消息速度不够快的话，不断积压的消息会使Redis输出缓冲的体积变得越来越大，可能会导致Redis的速度变慢，甚至崩溃。也可能会导致Redis被操作系统强制杀死，甚至导致操作系统不可用。新版的Redis不会出现这种问题，因为它会自动断开不符合<strong>client-output-buffer-limit pubsub</strong>配置选项要求的订阅客户端</li>
<li>如果客户端在执行订阅操作的过程中断线，那么客户端将丢失在断线期间发送的所有消息，因此pub/sub是不可靠的消息传递操作，有<strong>数据丢失风险</strong></li>
</ul>
<h3 id="其它命令">7 其它命令</h3>

<table>
<thead>
<tr>
<th>命令</th>
<th>用例和描述</th>
</tr>
</thead>
<tbody>
<tr>
<td>SORT</td>
<td><code>SORT source-key [BY pattern] [LIMIT　offset count] [GET pattern [GETpattern ...]] [ASC</code></td>
</tr>
<tr>
<td>PERSIS</td>
<td><code>PERSIST key-name</code> 移除健的过期时间</td>
</tr>
<tr>
<td>TTL</td>
<td><code>TTL key-name</code> 查看给定健距离过期还有多少秒</td>
</tr>
<tr>
<td>EXPIRE</td>
<td><code>EXPIRE key-name seconds</code> 让给定健在指定的秒数之后过期</td>
</tr>
<tr>
<td>EXPIREAT</td>
<td><code>EXPIREAT key-name timestamp</code> 让给定健在指定的unix时间戳之后过期</td>
</tr>
<tr>
<td>PEXPIRE</td>
<td><code>PEXPIRE key-name milliseconds</code> 让给定健在指定的毫秒数之后过期</td>
</tr>
<tr>
<td>PEXPIREAT</td>
<td><code>PEXPIREAT key-name timestamp-millisenconds</code> 将一个毫秒级精度的unix时间戳作为健的过期时间</td>
</tr>
<tr>
<td>ZSCORE</td>
<td><code>ZSCORE key-name member</code> 返回member的分值</td>
</tr>
</tbody>
</table>
