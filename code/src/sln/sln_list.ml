module String = struct
  let mem = CCList.mem ~eq:CCString.equal
  let sort = CCList.sort CCString.compare
  let equal = CCList.equal CCString.equal
  let uniq = CCList.uniq ~eq:CCString.equal
  let assoc_opt k l = CCList.assoc_opt ~eq:CCString.equal k l
end

module Uuidm = struct
  let mem = CCList.mem ~eq:Uuidm.equal
end
