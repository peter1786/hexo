---
title: Redis事务
date: 2017-03-18 21:00:36
tags:
	redis
categories:
	redis
  
---

对于一个传统的关系型数据库来说，数据库事务满足ACID四个特性：

-   A 代表**原子性**：一个事务中的所有操作，要么全部完成，要么全部不完成。事务在执行过程中发生错误，会被回滚（Rollback）到事务开始前的状态，就像这个事务从来没有执行过一样。
-   C 代表**一致性**：事务应确保数据库的状态从一个一致状态转变为另一个一致状态。一致状态的含义是数据库中的数据应满足完整性约束
-   I 代表**隔离性**：多个事务并发执行时，一个事务的执行不应影响其他事务的执行
-   D 代表**持久性**：已被提交的事务对数据库的修改应该永久保存在数据库中

Redis的事务跟传统关系形数据库的事务并不相同。对于Redis来说，只满足其中的：一致性和隔离性两个特性，其他特性是不支持的。




Redis事务以MULTI为开始，之后跟着多个命令，最后以EXEC结束。但是这种简单的事务在EXEC命令被调用之前不会执行任何实际操作。

|命令         |描述                   
|------------|------------------------------------------------- 
|MULTI       |开启事务
|EXEC        |执行事务
|WATCH       |对健监视，直到EXEC命令执行的这段时间，如果其它客户端对健进行修改，事务将失败
|UNWATCH     |用于取消watch命令对所有key的监视
|DISCARD     |对连接进行重置，取消WATCH命令并清空所有已入队的命令;在EXEC命令执行之前



<!--stackedit_data:
eyJoaXN0b3J5IjpbNzg0OTA1NDk1XX0=
-->