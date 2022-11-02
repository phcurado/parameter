defmodule Parameter.EnumTest do
  use ExUnit.Case

  defmodule EnumTest do
    import Parameter.Enum

    enum values: [:user_online, :user_offline]

    enum JobType do
      value :freelancer, key: "freelancer"
      value :business_owner, key: "businessOwner"
      value :unemployed, key: "unemployed"
      value :employed, key: "employed"
    end

    enum JobTypeInteger do
      value :freelancer, key: 1
      value :business_owner, key: 2
      value :unemployed, key: 3
      value :employed, key: 4
    end
  end

  describe "load/1" do
    test "load EnumTest" do
      assert EnumTest.load("user_online") == {:ok, :user_online}
      assert EnumTest.load("user_offline") == {:ok, :user_offline}
      assert EnumTest.load(:user_offline) == {:error, "invalid enum type"}
      assert EnumTest.load("userOnline") == {:error, "invalid enum type"}
    end

    test "load JobType" do
      assert EnumTest.JobType.load("freelancer") == {:ok, :freelancer}
      assert EnumTest.JobType.load("businessOwner") == {:ok, :business_owner}
      assert EnumTest.JobType.load("unemployed") == {:ok, :unemployed}
      assert EnumTest.JobType.load("employed") == {:ok, :employed}
      assert EnumTest.JobType.load("other") == {:error, "invalid enum type"}
    end

    test "load JobTypeInteger" do
      assert EnumTest.JobTypeInteger.load(1) == {:ok, :freelancer}
      assert EnumTest.JobTypeInteger.load(2) == {:ok, :business_owner}
      assert EnumTest.JobTypeInteger.load(3) == {:ok, :unemployed}
      assert EnumTest.JobTypeInteger.load(4) == {:ok, :employed}
      assert EnumTest.JobTypeInteger.load(5) == {:error, "invalid enum type"}
      assert EnumTest.JobTypeInteger.load("5") == {:error, "invalid enum type"}
      assert EnumTest.JobTypeInteger.load("employed") == {:error, "invalid enum type"}
    end
  end

  describe "dump/1" do
    test "dump EnumTest" do
      assert EnumTest.dump(:user_online) == {:ok, "user_online"}
      assert EnumTest.dump(:user_offline) == {:ok, "user_offline"}
      assert EnumTest.dump("user_offline") == {:error, "invalid enum type"}
      assert EnumTest.dump(:userOnline) == {:error, "invalid enum type"}
    end

    test "dump JobType" do
      assert EnumTest.JobType.dump(:freelancer) == {:ok, "freelancer"}
      assert EnumTest.JobType.dump(:business_owner) == {:ok, "businessOwner"}
      assert EnumTest.JobType.dump(:unemployed) == {:ok, "unemployed"}
      assert EnumTest.JobType.dump(:employed) == {:ok, "employed"}
      assert EnumTest.JobType.dump(:other) == {:error, "invalid enum type"}
    end

    test "dump JobTypeInteger" do
      assert EnumTest.JobTypeInteger.dump(:freelancer) == {:ok, 1}
      assert EnumTest.JobTypeInteger.dump(:business_owner) == {:ok, 2}
      assert EnumTest.JobTypeInteger.dump(:unemployed) == {:ok, 3}
      assert EnumTest.JobTypeInteger.dump(:employed) == {:ok, 4}
      assert EnumTest.JobTypeInteger.dump(:other) == {:error, "invalid enum type"}
      assert EnumTest.JobTypeInteger.dump("5") == {:error, "invalid enum type"}
      assert EnumTest.JobTypeInteger.dump(1) == {:error, "invalid enum type"}
      assert EnumTest.JobTypeInteger.dump("employed") == {:error, "invalid enum type"}
    end
  end
end
