module Oid : sig
  type t = {
    oid : int;
    array_oid : int;
  }

  val abstime : t

  val aclitem : t

  val any : t

  val anyrange : t

  val bit : t

  val bool : t

  val bpchar : t

  val bytea : t

  val char : t

  val cid : t

  val cidr : t

  val cstring : t

  val date : t

  val daterange : t

  val float4 : t

  val float8 : t

  val gtsvector : t

  val inet : t

  val int2 : t

  val int2vector : t

  val int4 : t

  val int4range : t

  val int8 : t

  val int8range : t

  val internal : t

  val json : t

  val jsonb : t

  val macaddr : t

  val macaddr8 : t

  val money : t

  val name : t

  val numeric : t

  val numrange : t

  val oid : t

  val oidvector : t

  val opaque : t

  val record : t

  val regproc : t

  val reltime : t

  val text : t

  val tid : t

  val time : t

  val timestamp : t

  val timestamptz : t

  val timetz : t

  val tinterval : t

  val trigger : t

  val tsquery : t

  val tsrange : t

  val tstzrange : t

  val tsvector : t

  val txid_snapshot : t

  val unknown : t

  val uuid : t

  val varbit : t

  val varchar : t

  val void : t

  val xid : t

  val xml : t
end