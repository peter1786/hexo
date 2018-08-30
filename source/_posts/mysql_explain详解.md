---
title: Mysql explain 详解
date: 2017-05-11 22:03:39
tags:
	mysql
categories:
	数据库
 
---


# 简介

MySQL 提供了一个 EXPLAIN 命令, 它可以提供mysql内部执行命令的一些信息。如  `SELECT`、`DELETE` ，`UPDATE` 、`INSERT`、 `UPDATE`、`REPLACE`   以供开发人员针对性优化.  
EXPLAIN 用法十分简单, 在 SQL语句前加上 EXPLAIN 就可以了, 例如:

```
EXPLAIN SELECT * from table WHERE id = 1;
```

## EXPLAIN 输出格式

|   Column    |解释                   
|------------|------------------------------------------ 
|id        |执行编号. 每个 SELECT 都会自动分配一个唯一的标识符.      
|select_type        |SELECT 查询的类型.
|table      |查询的是哪个表
|partitions       |匹配的分区   
|type       |数据访问/读取操作类型      
|possible_keys        |此次查询中可能选用的索引
|key        |此次查询中确切使用到的索引.
|key_len        | 索引里使用的字节数
|ref        | 哪个字段或常数与 key 一起被使用
|rows        |显示此查询一共扫描了多少行. 这个是一个估计值.
|filtered        |表示此查询条件所过滤的数据的百分比
|Extra   |额外的信息

   

## select_type

|type                 |解释                   
|----------------|------------------------------------------ 
|SIMPLE        |表示此查询不包含 UNION 查询或子查询,是最常见的查询类型。
|PRIMARY        |包含 UNION 查询或子查询, 表示此查询是最外层的查询
|UNION      |位于union中第二个及其以后的子查询被标记为union，第一个就被标记为primary如果是union位于from中则标记为derived
|DERIVED | 派生表——该临时表是从子查询派生出来的，位于form中的子查询
|DEPENDENT UNION      |UNION中的第二个或后面的查询语句, 取决于外面的查询
|UNION RESULT       |UNION 的结果  
|DEPENDENT UNION        |首先需要满足UNION的条件，及UNION中第二个以及后面的SELECT语句，同时该语句依赖外部的查询  
|SUBQUERY        |子查询中的第一个 SELECT
|DEPENDENT SUBQUERY        |子查询中的第一个 SELECT, 取决于外面的查询. 即子查询依赖于外层查询的结果.


## table

表示查询涉及的表或衍生表, 没太多可说的

## type

|value                 |解释                   
|------------|------------------------------------------ 
|system        |表中只有一条数据. 这个类型是特殊的  `const`  类型
|const        |针对主键或唯一索引的等值查询扫描, 最多只返回一行数据. const 查询速度非常快, 因为它仅仅读取一次即可.
|eq_ref        |最多只返回一条符合条件的记录。使用唯一性索引或主键查找时会发生
|ref        |一种索引访问，它返回所有匹配某个单个值的行。此类索引访问只有当使用非唯一性索引或唯一性索引非唯一性前缀时才会发生。这个类型跟eq_ref不同的是，它用在关联操作只使用了索引的最左前缀，或者索引不是UNIQUE和PRIMARY KEY。ref可以用于使用=或<=>操作符的带索引的列
|range        | 表示使用索引范围查询, 通过索引字段范围获取表中部分数据记录. 这个类型通常出现在 `=, <>, >, >=, <, <=, IS NULL, <=>, BETWEEN, IN()` 操作中.
|index | 和全表扫描一样。只是扫描表的时候按照索引次序进行而不是行。主要优点就是避免了排序, 但是开销仍然非常大。如在Extra列看到Using index，说明正在使用覆盖索引，只扫描索引的数据，它比按索引次序全表扫描的开销要小很多 
|all | 表示全表扫描, 这个类型的查询是性能最差的查询之一
|null | 意味说mysql能在优化阶段分解查询语句，在执行阶段甚至用不到访问表或索引



通常来说, 不同的 type 类型的性能关系如下:  
`ALL < index < range ~ index_merge < ref < eq_ref < const < system`  


## possible_keys

`possible_keys`  表示 MySQL 在查询时, 能够使用到的索引. 注意, 即使有些索引在  `possible_keys`  中出现, 但是并不表示此索引会真正地被 MySQL 使用到. MySQL 在查询时具体使用了哪些索引, 由  `key`  字段决定.

## key

此字段是 MySQL 在当前查询时所真正使用到的索引.

## key_len

表示查询优化器使用了索引的字节数. 这个字段可以评估组合索引是否完全被使用, 或只有最左部分字段被使用到.  在不损失精确性的情况下，长度越短越好
key_len 的计算规则如下:

-   字符串
    
    -   char(n): n 字节长度
        
    -   varchar(n): 如果是 utf8 编码, 则是 3  n + 2字节; 如果是 utf8mb4 编码, 则是 4_ n + 2 字节.
        
-   数值类型:
    
    -   TINYINT: 1字节
        
    -   SMALLINT: 2字节
        
    -   MEDIUMINT: 3字节
        
    -   INT: 4字节
        
    -   BIGINT: 8字节
        
-   时间类型
    
    -   DATE: 3字节
        
    -   TIMESTAMP: 4字节
        
    -   DATETIME: 8字节
        
-   字段属性: NULL 属性 占用一个字节. 如果一个字段是 NOT NULL 的, 则没有此属性.
    

## rows

 MySQL 查询优化器根据统计信息, 估算 SQL 要查找到结果集需要扫描读取的数据行数.  这个值非常直观显示 SQL 的效率好坏, 原则上 rows 越少越好.

## Extra

EXPLAIN 中的很多额外的信息会在 Extra 字段显示, 常见的有以下几种内容:


|value                 |解释                   
|------------|------------------------------------------ 
|Using filesort    |MySQL有两种方式可以生成有序的结果，通过排序操作或者使用索引，当Extra中出现了Using filesort 说明MySQL使用了后者. 一般有  `Using filesort`, 都建议优化去掉, 因为这样的查询 CPU 资源消耗大.
|const        |针对主键或唯一索引的等值查询扫描, 最多只返回一行数据. const 查询速度非常快, 因为它仅仅读取一次即可.
| Using index   | 从索引树（索引文件）中即可获得信息。如果同时出现using where，表明索引被用来执行索引键值的查找，没有using where，表明索引用来读取数据而非执行查找动作
| Using temporary   | 查询有使用临时表, 一般出现于排序, 分组和多表 join 的情况, 查询效率不高, 建议优化.
|Not exists  | MYSQL优化了LEFT JOIN，一旦它找到了匹配LEFT JOIN标准的行， 就不再搜索了。
| Using index condition | 这是MySQL 5.6出来的新特性，叫做“索引条件推送”。简单说一点就是MySQL原来在索引上是不能执行如like这样的操作的，但是现在可以了，这样减少了不必要的IO操作，但是只能用在二级索引上。
| Using where | 使用了WHERE从句来限制哪些行将与下一张表匹配或者是返回给用户。**注意**：Extra列出现Using where表示MySQL服务器将存储引擎返回服务层以后再应用WHERE条件过滤。
| Using join buffer | 使用了连接缓存：**Block Nested Loop**，连接算法是块嵌套循环连接;**Batched Key Access**，连接算法是批量索引连接
| impossible where | where子句的值总是false，不能用来获取任何元组
| select tables optimized away | 在没有GROUP BY子句的情况下，基于索引优化MIN/MAX操作，或者对于MyISAM存储引擎优化COUNT(*)操作，不必等到执行阶段再进行计算，查询执行计划生成的阶段即完成优化。
| distinct优化distinct操作，在找到第一匹配的元组后即停止找同样值的动作

  

## 参考

https://dev.mysql.com/doc/refman/8.0/en/explain-output.html
