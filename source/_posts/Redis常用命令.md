---
title: Redis常用命令
date: 2017-03-11 13:00:36
tags:
	redis
categories:
	nosql
  
---

###  STRING

 Redis的字符串是一个由字节组成的序列，可以存储3种类型的值：**字节串，整数，浮点数。**

|命令                 |用例和描述                   
|------------|------------------------------------------
|GET         |`GET key-name` 获取健值      
|SET         |`SET key-name` 设置健值
|DEL         |`DEL key-name` 删除健   
|INCR        |`INCR key-name` 将键值加1      
|DECR        |`DECR key-name` 将键值减1           
|INCRBY      |`INCRBY key-name amount` 将健值加上amount
|DECRBY      |`DECRBY key-name amount` 将健值减上amount
|INCRBYFLOAT |`INCRBYFLOAT key-name amount` 将健值减上浮点数amount
|APPEND      |`APPEND key-name value` 将值value追加到key-name的末尾
|GETRANGE    |`GETRANGE key-name start end` 获取偏移量start至end范围的子串，包括start和end在内           
|SETRANGE    |`SETRANGE key-name offset value` 将从start开始的子串设置为value
|GETBIT      |`GETBIT key-name offset` 将字符串看到二进制位串，返回偏移量为offset的值
|SETBIT      |`SETBIT key-name offset value` 将字符串看到二进制位串，将偏移量为offset的值设置为value
|BITCOUNT    |`BITCOUNT key-name [start,end]` 统计比特位值为1的数量
|BITOP       |`BITOP operation dest-key key-name [key-name ...]`对一个或多个二进制位串执行包括 **并（AND）**、**或（OR）**、**异或（XOR**）、**非（NOT）**在内的任意一种按位运算操作，并将结果保存在dest_key键里面

- 对于一个保存了空串或不存在的健进行自增自减速，Redis会将健当成0来处理。如果对一个值无法被解释为整数或者浮点数的健进行自增自减操作，Redis会返回一个错误。
- 如果使用setrangea或者SETBIT写入的时候，字符串当前的长度不能满足，那么Redis会自动地使用空字节（null）来填充，然后再执行写入操作

###  LIST

|命令           |用例和描述                   
|--------------|------------------------------------------ 
|RPUSH         |`RPUSH key-name value [value ...]` 将一个或多个值推入列表的右端      
|LPUSH         |`LPUSH key-name value [value ...]` 将一个或多个值推入列表的左端             
|RPOP          |`RPOP key-name` 移除并返回列表最右端的元素
|LPOP          |`RPOP key-name` 移除并返回列表最左端的元素
|LINDEX        |`LINDEX key-name offset` 返回列表中偏移量为offset的元素
|LRANGE        |`LRANGE key-name start end` 返回start到end（包括start和end）偏移量范围内的所有元素
|LTRIM         |`LTRIM key-name start end` 对列表进行修剪，只保留start至end范围的元素，包括start和end在内          
|BLPOP         |`BLPOP key-name [key-name ...] timeout` 从第一个非空列表中弹出位于最左端的元素，或者在timeout秒之内阻塞并等待可弹出的元素出现
|BRPOP         |`BRPOP key-name [key-name ...] timeout` 从第一个非空列表中弹出位于最右端的元素，或者在timeout秒之内阻塞并等待可弹出的元素出现
|RPOPLPUSH     |`RPOPLPUSH source-key dest-key` 从source-key列表中弹出位于最右边端的元素，然后将这个元素推入到dest-key的最左端，并向用户返回这个元素
|BRPOPLPUSH     |`BRPOPLPUSH source-key dest-key` 从source-key列表中弹出位于最右边端的元素，然后将这个元素推入到dest-key的最左端，并向用户返回这个元素。如果source-key为空，那么在timeout秒之内阻塞并等待可弹出的元素出现

###  SET

|命令         |用例和描述                   
|------------|------------------------------------------ 
|SADD        |`SADD key-name item [item ...]` 将一个或多个元素添加到集合，并返回被添加元素当中原本不存在于集合里面的元素数量      
|SREM        |`SREM key-name item [item ...]` 从集合里面移除一个或多个元素，并返回移除的数量           
|SISMEMBER   |`SISMEMBEER key-name item` 检查元素是否在于集合中
|SCARD       |`SCARD key-name` 返回集合中元素的数量
|SMEMBERS    |`SMEMBERS key-name` 返回所有的元素
|SRANDMEMBER |`SRANDMEMBER key-name [count]` 随机返回一个或多个元素。当count为正整数时，命令返回的元素不会重复。当count为负数时，命令返回的随机元素可能会出现重复
|SPOP        |`SPOP key-name` 随机移除集合中的一个元素，并返回移除的元素           
|SMOVE       |`SMOVE source-key dest-key item` 如果source-key包含元素item,那么从source-key里面移除该元素，并将该元素添加到dest-key集合中。成功返回1，否则为0
|SDIFF       |`SDIFF key-name [key-name ...]` 返回那些存在于第一个集合，不存在于其它集合中的元素
|SDIFFSTORE  |`SDIFFSTORE dest-key key-name [key-name ...]` 将那些在于第一个集合，不存在于其它集合中的元素存储到dest-key集合里面
|SINTER      |`SINTER key-name [key-name ...]` 返回同时存在于所有集合中的元素           
|SINTERSTORE |`SINTERSTORE dest-key key-name [key-name ...]` 将同时存在于所有集合中的元素放到dest-key集合里面
|SUNION      |`SUNION key-name [key-name ...]` 返回那些至少存在于一个集合中的元素         
|SUNIONSTORE |`SUNIONSTORE dest-key key-name [key-name ...]` 将那些至少存在于一个集合中的元素放到dest-key集合里面

###  HASH

|命令                 |用例和描述                   
|------------|------------------------------------------ 
|HGET        |`HMGET key-name key ` 获取一个健的值      
|HSET        |`HMSET key-name key value ` 为散列里面的一个健设置值
|HGETAL      |`HGETALL key-name` 获取所有的健值对
|HMGET       |`HMGET key-name key [key...]` 从散列里面获取一个或多个健的值      
|HMSET       |`HMSET key-name key value [key value...]` 为散列里面的一个或多个健设置值           
|HDEL        |`HDEL key-name key [key ...]` 删除一个或多个健，并返回成功的数量
|HLEN        |`HLEN key-name` 返回散列里包含的健值对数量
|SMEMBERS    |`SMEMBERS key-name` 返回所有的元素
|HEXIST      |`HEXIST key-name key` 检查给定的健是否存在     
|HKEYS       |`HKEYS key-name` 获取所有的健           
|HVALS       |`HVALS key-name` 获取所有的值
|HINCRBY     |`HINCRBY key-name key increment` 自增加整数increment
|HINCRBYFLOAT|`HINCRBYFLOAT key-name key increment` 自增加浮点数increment

###  ZSET

|命令         |用例和描述                   
|------------|------------------------------------------ 
|ZADD        |`ZADD key-name score member[score member ...]` 将带有指定分值的成员添加到集合里面      
|ZREM        |`ZREM key-name member [member...]` 从集合里面移除一个或多个成员，并返回移除的数量  
|ZCARD       |`ZCARD key-name` 返回集合中成员的数量
|ZINCRBY     |`ZINCRBY key-name increment member` 给member的分值加上increment
|ZCOUNT      |`ZOUNT key-name min max` 返回分值介于min和max之间的成员数
|ZRANK       |`ZRANK key-name member` 返回member的排名        
|ZSCORE      |`ZSCORE key-name member` 返回member的分值
|ZRANGE      |`ZRANGE key-name start stop [withscores]` 返回排名介于start和stop之间的成员，如果指定了withscores选项，那么把成员的分值也一并返回  
|ZREVRANK    |`ZREVRANK key-name member` 返回member的排名,按照分值从大小到排列 
|ZREVRANGE   |`ZREVRANGE key-name start stop [withscores]` 返回排名介于start和stop之间的成员，按照分值从大小到排列
|ZRANGEBYSCORE    |`ZRANGEBYSCORE key-name min max [withscores] [limit offset count]` 返回分值介于min和max之间的成员
|ZREVRANGEBYSCORE |`ZREVRANGEBYSCORE key-name min max [withscores] [limit offset count]` 按照分值从大小到排列，返回分值介于min和max之间的成员,
|ZREMRANGEBYRANK  |`ZREMRANGEBYRANK  key-name start stop` 删除排名位于start和stop之间的所有成员
|ZREMRANGEBYSCORE |`ZREMRANGEBYSCORE key-name min max` 删除分值位于min和max之间的所有成员
|ZINTERSTORE      |`ZINTERSTORE dest-key key-count key [key ...] [WEIGHTS weight [weight]] [AGGREGATE SUM丨MIN丨MAX]` 计算给定的一个或多个有序集的交集，其中给定 key 的数量必须以 key-count参数指定，并将该并集(结果集)储存到 dest-key。默认情况下，结果集中某个成员的 score 值是所有给定集下该成员 score 值之和
|ZUNIONSTORE      |`ZUNIONSTORE dest-key key-count key [key ...] [WEIGHTS weight [weight]] [AGGREGATE SUM丨MIN丨MAX]` 计算给定的一个或多个有序集的并集，其中给定 key 的数量必须以 key-count参数指定，并将该并集(结果集)储存到 dest-key。默认情况下，结果集中某个成员的 score 值是所有给定集下该成员 score 值之和

- `WEIGHTS`  选项，你可以为  *每个* 给定有序集  *分别*  指定一个乘法因子(multiplication factor)，每个给定有序集的所有成员的  `score`  值在传递给聚合函数(aggregation function)之前都要先乘以该有序集的因子。如果没有指定  `WEIGHTS`  选项，乘法因子默认设置为  `1`  。
- `AGGREGATE` 选项，你可以指定并集的结果集的聚合方式。

###  pub/sub

|命令         |用例和描述                   
|------------|------------------------------------------ 
|SUBSCRIBE   |`SUBSCRIBE channel [channel ...]` 订阅给定的一个或多个频道      
|UNSUBSCRIBE |`UNSUBSCRIBE [channel [channel ...]]` 退订给定的一个或多个频道,没有指定则退妯所有频道 
|PUBLISH     |`PUBLISH channel message` 向指定频道发送消息
|PSUBSCRIBE  |`PSUBSCRIBE pattern [pattern ...]` 订阅与给定模式相匹配的所有频道
|PUNSUBSCRIBE|`PUNSUBSCRIBE [pattern [pattern ...][` 退订给定的模式,如果没有指定则退订所有模式
- 旧版Redis如果客户端读取消息速度不够快的话，不断积压的消息会使Redis输出缓冲的体积变得越来越大，可能会导致Redis的速度变慢，甚至崩溃。也可能会导致Redis被操作系统强制杀死，甚至导致操作系统不可用。新版的Redis不会出现这种问题，因为它会自动断开不符合**client-output-buffer-limit pubsub**配置选项要求的订阅客户端
- 如果客户端在执行订阅操作的过程中断线，那么客户端将丢失在断线期间发送的所有消息，因此pub/sub是不可靠的消息传递操作，有**数据丢失风险**

###  其它命令

|命令         |用例和描述                   
|------------|------------------------------------------------- 
|SORT        |`SORT source-key [BY pattern] [LIMIT　offset count] [GET pattern [GETpattern ...]] [ASC丨DESC] [ALPHA] [STORE dest-key]` 根据指定的选项，对输入的列表、集合或者有序集合进行排序，然后返回或者存储排序的结果
|PERSIS      |`PERSIST key-name` 移除健的过期时间
|TTL         |`TTL key-name` 查看给定健距离过期还有多少秒
|EXPIRE      |`EXPIRE key-name seconds` 让给定健在指定的秒数之后过期 
|EXPIREAT    |`EXPIREAT key-name timestamp` 让给定健在指定的unix时间戳之后过期 
|PEXPIRE     |`PEXPIRE key-name milliseconds` 让给定健在指定的毫秒数之后过期
|PEXPIREAT   |`PEXPIREAT key-name timestamp-millisenconds` 将一个毫秒级精度的unix时间戳作为健的过期时间      
|ZSCORE      |`ZSCORE key-name member` 返回member的分值


