module DBus
module Type
  INVALID = 0
  BYTE = ?y
  BOOLEAN = ?b
  INT16 = ?n
  UINT16 = ?q
  INT32 = ?i
  UINT32 = ?u
  INT64 = ?x
  UINT64 = ?t
  DOUBLE = ?d
  STRUCT = ?r
  ARRAY = ?a
  VARIANT = ?v
  OBJECT_PATH = ?o
  STRING = ?s
  SIGNATURE = ?g
  DICT_ENTRY = ?e

  TypeName = {
    INVALID => "INVALID",
    BYTE => "BYTE",
    BOOLEAN => "BOOLEAN",
    INT16 => "INT16",
    UINT16 => "UINT16",
    INT32 => "INT32",
    UINT32 => "UINT32",
    INT64 => "INT64",
    UINT64 => "UINT64",
    DOUBLE => "DOUBLE",
    STRUCT => "STRUCT",
    ARRAY => "ARRAY",
    VARIANT => "VARIANT",
    OBJECT_PATH => "OBJECT_PATH",
    STRING => "STRING",
    SIGNATURE => "SIGNATURE",
    DICT_ENTRY => "DICT_ENTRY"
  }

  class SignatureException < Exception
  end

  class Type
    attr_reader :sigtype, :members
    def initialize(sigtype)
      if not TypeName.keys.member?(sigtype)
        raise SignatureException, "Unknown key in signature: #{sigtype.chr}"
      end
      @sigtype = sigtype
      @members = Array.new
    end

    def to_s
      case @sigtype
      when STRUCT
        "(" + @members.collect { |t| t.to_s }.join + ")"
      when ARRAY
        "a" + @members.collect { |t| t.to_s }
      when DICT_ENTRY
        "{" + @members.collect { |t| t.to_s }.join + "}"
      else
        if not TypeName.keys.member?(@sigtype)
          raise NotImplementedException
        end
        @sigtype.chr
      end
    end

    def <<(a)
      if not [STRUCT, ARRAY, DICT_ENTRY].member?(@sigtype)
        raise SignatureException 
      end
      raise SignatureException if @sigtype == ARRAY and @members.size > 0
      if @sigtype == DICT_ENTRY
        if @members.size == 2
          raise SignatureException, "Dict entries have exactly two members"
        end
        if @members.size == 0
          if [STRUCT, ARRAY, DICT_ENTRY].member?(a.sigtype)
            raise SignatureException, "Dict entry keys must be basic types"
          end
        end
      end
      @members << a
    end

    def child
      @members[0]
    end

    def inspect
      s = TypeName[@sigtype]
      if [STRUCT, ARRAY].member?(@sigtype)
        s += ": " + @members.inspect
      end
      s
    end
  end

  class Parser
    def initialize(signature)
      @signature = signature
      @idx = 0
    end

    def nextchar
      c = @signature[@idx]
      @idx += 1
      c
    end

    def parse_one(c)
      res = nil
      case c
      when ?a
        res = Type.new(ARRAY)
        child = parse_one(nextchar)
        res << child
      when ?(
        res = Type.new(STRUCT)
        while (c = nextchar) != nil and c != ?)
          res << parse_one(c)
        end
        raise SignatureException, "Parse error in #{@signature}" if c == nil
      when ?{
        res = Type.new(DICT_ENTRY)
        while (c = nextchar) != nil and c != ?}
          res << parse_one(c)
        end
        raise SignatureException, "Parse error in #{@signature}" if c == nil
      else
        res = Type.new(c)
      end
      res
    end

    def parse
      @idx = 0
      ret = Array.new
      while (c = nextchar)
        ret << parse_one(c)
      end
      ret
    end
  end
end
end