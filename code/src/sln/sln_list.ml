module String = struct
  let mem = CCList.mem ~eq:CCString.equal
  let sort = CCList.sort CCString.compare
  let equal = CCList.equal CCString.equal
  let uniq = CCList.uniq ~eq:CCString.equal
end

module Uuidm = struct
  let mem = CCList.mem ~eq:Uuidm.equal
end
