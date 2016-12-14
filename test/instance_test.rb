require File.expand_path(File.join(__FILE__, '..', 'test_helper'))

class InstanceTest < Minitest::Test
  include Rubber::Configuration
  
  def instance_setup
    @instance = Instance.new("file:#{Tempfile.new('testforrole').path}")
    @instance.add(@i1 = InstanceItem.new('host1', 'domain.com', [RoleItem.new('role1')], '', 'm1.small', 'ami-7000f019'))
    @instance.add(@i2 = InstanceItem.new('host2', 'domain.com', [RoleItem.new('role1')], '', 'm1.small', 'ami-7000f019'))
    @instance.add(@i3 = InstanceItem.new('host3', 'domain.com', [RoleItem.new('role2')], '', 'm1.small', 'ami-7000f019'))
    @instance.add(@i4 = InstanceItem.new('host4', 'domain.com', [RoleItem.new('role2', 'primary' => true)], '', 'm1.small', 'ami-7000f019'))
  end

  context "instance" do
  
    setup do
      instance_setup
    end
    
    context "for_role" do
    
      should "give the right instances for selected role" do
        assert_equal 2, @instance.for_role('role1').size, 'not finding correct instances for role'
        assert_equal 2, @instance.for_role('role2').size, 'not finding correct instances for role'
        assert_equal 1, @instance.for_role('role2', {}).size, 'not finding correct instances for role'
        assert_equal @i3, @instance.for_role('role2', {}).first, 'not finding correct instances for role'
        assert_equal 1, @instance.for_role('role2', 'primary' => true).size, 'not finding correct instances for role'
        assert_equal @i4, @instance.for_role('role2', 'primary' => true).first, 'not finding correct instances for role'
      end
      
    end
      
    context "filtering" do
      
      should "not filter for empty FILTER(_ROLES)" do
        ENV['FILTER'] = nil
        ENV['FILTER_ROLES'] = nil
        instance_setup
        assert_equal 4, @instance.filtered().size 
      end
    
    
      should "filter hosts" do
        ENV['FILTER_ROLES'] = nil
        ENV['FILTER'] = 'host1'
        instance_setup
        assert_equal [@i1].sort, @instance.filtered().sort, 'should have only filtered host'
        
        ENV['FILTER'] = 'host2 , host4'
        instance_setup
        assert_equal [@i2, @i4].sort, @instance.filtered().sort, 'should have only filtered hosts'
    
        ENV['FILTER'] = '-host2'
        instance_setup
        assert_equal [@i1, @i3, @i4].sort, @instance.filtered().sort, 'should not have negated hosts'
    
        ENV['FILTER'] = 'host1,host2,-host2'
        instance_setup
        assert_equal [@i1].sort, @instance.filtered().sort, 'should not have negated hosts'
    
        ENV['FILTER'] = 'host1~host3'
        instance_setup
        assert_equal [@i1, @i2, @i3].sort, @instance.filtered().sort, 'should allow range in filter'
    
        ENV['FILTER'] = '-host1~-host3'
        instance_setup
        assert_equal [@i4].sort, @instance.filtered().sort, 'should allow negative range in filter'
    
        ENV['FILTER'] = '-host1'
        ENV['FILTER_ROLES'] = 'role1'
        instance_setup
        assert_equal [@i2].sort, @instance.filtered().sort, 'should not have negated roles'
      end
    
      should "filter roles" do
        ENV['FILTER'] = nil
        ENV['FILTER_ROLES'] = 'role1'
        instance_setup
        assert_equal [@i1, @i2].sort, @instance.filtered().sort, 'should have only filtered roles'
    
        ENV['FILTER_ROLES'] = 'role1 , role2'
        instance_setup
        assert_equal [@i1, @i2, @i3, @i4].sort, @instance.filtered().sort, 'should have only filtered roles'
    
        ENV['FILTER_ROLES'] = '-role1'
        instance_setup
        assert_equal [@i3, @i4].sort, @instance.filtered().sort, 'should not have negated roles'
    
        ENV['FILTER_ROLES'] = 'role1~role2'
        instance_setup
        assert_equal [@i1, @i2, @i3, @i4].sort, @instance.filtered().sort, 'should allow range in filter'
    
        ENV['FILTER_ROLES'] = '-role1~-role2'
        instance_setup
        assert_equal [].sort, @instance.filtered().sort, 'should allow negative range in filter'
      end
    
      should "validate filters" do
        ENV['FILTER'] = "nohost"
        instance_setup
        assert_raises do
          @instance.filtered()
        end
    
        ENV['FILTER'] = "-nohost"
        instance_setup
        assert_raises do
          @instance.filtered()
        end
    
        ENV['FILTER_ROLES'] = "norole"
        instance_setup
        assert_raises do
          @instance.filtered()
        end
    
        ENV['FILTER_ROLES'] = "-norole"
        instance_setup
        assert_raises do
          @instance.filtered()
        end
      end
      
    end
      
  
    should "be equal" do
      assert RoleItem.new('a').eql?(RoleItem.new('a'))
      assert RoleItem.new('a') == RoleItem.new('a')
      assert_equal RoleItem.new('a').hash, RoleItem.new('a').hash
  
      assert ! RoleItem.new('a').eql?(RoleItem.new('b'))
      assert RoleItem.new('a') != RoleItem.new('b')
      refute_equal RoleItem.new('a').hash, RoleItem.new('b').hash
  
      assert RoleItem.new('a', {'a' => 'b', 1 => true}).eql?(RoleItem.new('a', {'a' => 'b', 1 => true}))
      assert RoleItem.new('a', {'a' => 'b', 1 => true}) == RoleItem.new('a', {'a' => 'b', 1 => true})
      assert_equal RoleItem.new('a', {'a' => 'b', 1 => true}).hash, RoleItem.new('a', {'a' => 'b', 1 => true}).hash
  
      assert ! RoleItem.new('a', {'a' => 'b', 1 => true}).eql?(RoleItem.new('a', {'a' => 'b', 2 => true}))
      assert RoleItem.new('a', {'a' => 'b', 1 => true}) != RoleItem.new('a', {'a' => 'b', 2 => true})
      assert_equal RoleItem.new('a', {'a' => 'b', 1 => true}).hash, RoleItem.new('a', {'a' => 'b', 2 => true}).hash
    end
  
    should "parse roles" do
      assert_equal RoleItem.new('a'), RoleItem.parse("a")
      assert_equal RoleItem.new('a', {'b' => 'c'}), RoleItem.parse("a:b=c")
      assert_equal RoleItem.new('a', {'b' => 'c', 'd' => 'e'}), RoleItem.parse("a:b=c;d=e")
      assert_equal RoleItem.new('a', {'b' => true, 'c' => false}), RoleItem.parse("a:b=true;c=false")
    end
  
    should "convert to a string" do
      assert_equal "a", RoleItem.new('a').to_s
      assert_equal "a:b=c", RoleItem.new('a', {'b' => 'c'}).to_s
      str = RoleItem.new('a', {'b' => 'c', 'd' => 'e'}).to_s
      assert ["a:b=c;d=e", "a:d=e;b=c"].include?(str)
      assert_equal "a:b=true", RoleItem.new('a', {'b' => true}).to_s
      assert_equal "a:b=false", RoleItem.new('a', {'b' => false}).to_s
    end
  
    context "role dependencies" do
      
      should "expand role dependencies" do
        deps = { RoleItem.new('a') => RoleItem.new('b'),
                 RoleItem.new('b') => RoleItem.new('c'),
                 RoleItem.new('c') => [RoleItem.new('d'), RoleItem.new('a')]}
        roles = [RoleItem.new('a'),RoleItem.new('b'),RoleItem.new('c'),RoleItem.new('d')]
        assert_equal roles, RoleItem.expand_role_dependencies(RoleItem.new('a'), deps).sort
        assert_equal roles, RoleItem.expand_role_dependencies([RoleItem.new('a'), RoleItem.new('d')], deps).sort
    
        deps = { RoleItem.new('mysql_master') => RoleItem.new('db', {'primary' => true}),
                 RoleItem.new('mysql_slave') => RoleItem.new('db'),
                 RoleItem.new('db', {'primary' => true}) => RoleItem.new('mysql_master'),
                 RoleItem.new('db') => RoleItem.new('mysql_slave')
        }
        assert_equal [RoleItem.new('db', 'primary' => true), RoleItem.new('mysql_master')],
                     RoleItem.expand_role_dependencies(RoleItem.new('mysql_master'), deps).sort
        assert_equal [RoleItem.new('db', 'primary' => true), RoleItem.new('mysql_master')],
                     RoleItem.expand_role_dependencies(RoleItem.new('db', 'primary' => true), deps).sort
        assert_equal [RoleItem.new('db'), RoleItem.new('mysql_slave')],
                     RoleItem.expand_role_dependencies(RoleItem.new('mysql_slave'), deps).sort
        assert_equal [RoleItem.new('db'), RoleItem.new('mysql_slave')],
                     RoleItem.expand_role_dependencies(RoleItem.new('db'), deps).sort
    
      end
    
      should "expand dependencie for common role" do
        deps = { RoleItem.new('a') => RoleItem.new('b'),
                 RoleItem.new('common') => [RoleItem.new('c')]}
        roles = [RoleItem.new('a'), RoleItem.new('b'), RoleItem.new('c')]
        assert_equal roles, RoleItem.expand_role_dependencies(RoleItem.new('a'), deps).sort
      end
      
    end
    
    context "instance items" do
      
      setup do
        @hash = {
            'name' => 'host1',
            'domain' => 'domain.com',
            'roles' => ['role1', 'db:primary=true'],
            'instance_id' => 'xxxyyy',
            'image_type' => 'm1.small',
            'image_id' => 'ami-7000f019',
            'security_groups' => ['sg1', 'sg2']
        }
      end
      
      should "create from a hash" do
        item = InstanceItem.from_hash(@hash)
        assert_equal 'host1', item.name
        assert_equal 'domain.com', item.domain
        assert_equal [RoleItem.new('role1'), RoleItem.new('db', {'primary' => true})], item.roles
        assert_equal 'xxxyyy', item.instance_id
        assert_equal 'm1.small', item.image_type
        assert_equal 'ami-7000f019', item.image_id
        assert_equal ['sg1', 'sg2'], item.security_groups
      end
      
      should "output as a hash" do
        item = InstanceItem.new('host1',
                                 'domain.com',
                                 [RoleItem.new('role1'), RoleItem.new('db', {'primary' => true})],
                                 'xxxyyy',
                                 'm1.small',
                                 'ami-7000f019',
                                 ['sg1', 'sg2'])
        assert_equal @hash, item.to_hash()
      end
      
    end
    
  end
  
end
