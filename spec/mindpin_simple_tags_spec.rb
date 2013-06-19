# -*- encoding : utf-8 -*-
require 'spec_helper.rb'

class UserMigration < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string :name
    end
  end

  def self.down
    drop_table :users
  end
end

class BookMigration < ActiveRecord::Migration
  def self.up
    create_table :books, :force => true do |t|
      t.string :name
      t.integer :creator_id
    end
  end

  def self.down
    drop_table :books
  end
end

class User < ActiveRecord::Base
  simple_taggable
end

class Book < ActiveRecord::Base
  belongs_to :creator, :class_name => 'User'

  simple_taggable
end

describe MindpinSimpleTags do
  before(:all){
    UserMigration.up
    BookMigration.up
    MindpinSimpleTagsMigration.up
  }

  after(:all){
    UserMigration.down
    BookMigration.down
    MindpinSimpleTagsMigration.down
  }

  describe Book do
    before{
      @user_1 = User.create!(:name => 'user_1')
      @user_2 = User.create!(:name => 'user_2')

    }

    describe '标记TAG' do
      before{
        @creator = User.create!(:name => 'book_creator')
        @book = Book.create!(:name => 'Thinking in JAVA', :creator => @creator)
      }

      it{
        @book.public_tags.should == []
      }

      it{
        @book.private_tags(@user_1).should == []
      }

      it{
        @book.private_tags(@creator).should == []
      }

      describe 'media_resource_creator 可以给 media_resource 标记TAG。凡是creator标记的TAG，直接作为公共TAG' do
        context 'set_tag_list(str)' do
          before{
            @book.set_tag_list("编程,java，api 教程")  
          }

          it{
            @book.public_tags.map(&:name).should =~ ['编程','java','api','教程'] 
          }

          it{
            @book.private_tags(@user_1).should == []
          }

          it{
            @book.private_tags(@creator).map(&:name).should =~ ['编程','java','api','教程']
          }
        end

        context 'set_tag_list(str,:user=> creator)' do
          before{
            @book.set_tag_list("编程,java，api 教程", :user => @book.creator)  
          }

          it{
            @book.public_tags.map(&:name).should =~ ['编程','java','api','教程'] 
          }

          it{
            @book.private_tags(@user_1).should == []
          }

          it{
            @book.private_tags(@creator).map(&:name).should =~ ['编程','java','api','教程']
          }
        end
      end
      
      describe '所有非 media_resource_creator 的其他人，都可以给 media_resource 标记TAG。凡是非 media_resource_creator 标记的TAG，不作为公共TAG，只影响标记者的查询结果。' do
        context 'set_tag_list(str,:user => user)' do
          before{
            @book.set_tag_list("编程,java，api 教程", :user => @user_1)
          }

          it{
            @book.public_tags.should == []
          }

          it{
            @book.private_tags(@user_1).map(&:name).should =~ ['编程','java','api','教程'] 
          }
        end
      end

      describe '如果恰巧有两个或两个以上（>1）的非资源creator对某个资源标记了同名TAG，则该TAG被作为公共TAG；' do
        before{
          @book.set_tag_list("编程,java，api", :user => @user_1)
          @book.set_tag_list("java，api 教程", :user => @user_2)
        }

        it{
          @book.public_tags.map(&:name).should =~ ['java','api'] 
        }

        it{
          @book.private_tags(@user_1).map(&:name).should =~ ['编程','java','api'] 
        }

        it{
          @book.private_tags(@user_2).map(&:name).should =~ ['java','api','教程']
        }

        it{
          @book.private_tags(@creator).should == []
        }

        context '如果一个公共TAG，是被多于一个人（非 creator）标记才变为的公共TAG，当人数变为少于两人时，取消该TAG的公共属性' do
          before{
            @book.set_tag_list("java", :user => @user_2)
          }

          it{
            @book.private_tags(@user_2).map(&:name).should =~ ['java']
          }

          it{
            @book.public_tags.map(&:name).should =~ ['java']
          }

          context 'creator 重新标记TAG' do
            before{
              @book.set_tag_list("api")
              @book.set_tag_list("java 编程", :user => @user_1)
            }

            it{
              @book.private_tags(@user_1).map(&:name).should =~ ['java','编程']
            }

            it{
              @book.private_tags(@user_2).map(&:name).should =~ ['java'] 
            }

            it{
              @book.private_tags(@creator).map(&:name).should =~ ['api']
            }

            it{
              @book.public_tags.map(&:name).should =~ ['java','api']
            }
          end
        end
      end

      describe '#set_tag_list' do
        context '大小写' do
          before {
            @book.set_tag_list 'AJAX,Java,W3C', :user => @creator
          }

          it {
            @book.public_tags.map(&:name).
              should =~ %w(ajax w3c java)
          }

          it {
            @book.private_tags(@creator).map(&:name).
              should =~ %w(ajax w3c java)
          }
        end

        context '重复检查' do
          before {
            @book.set_tag_list 'AJAX,Java,W3C,abc,ABC,aBC', :user => @creator
          }

          it {
            @book.public_tags.map(&:name).
              should =~ %w(ajax w3c java abc)
          }

          it {
            @book.private_tags(@creator).map(&:name).
              should =~ %w(ajax w3c java abc)
          }
        end
      end

      describe '#update_public_tags' do
        before {
          @book.set_tag_list '苹果,橘子,香蕉', :user => @creator
        }

        it {
          @book.public_tags.map(&:name).
            should =~ %w(苹果 香蕉 橘子)
        }

        it { @book.private_tags(@user_1).should be_blank }

        it { @book.private_tags(@user_2).should be_blank }

        context '第一个非所有者添加了tag' do
          before {
            @book.set_tag_list '西瓜,芒果,猕猴桃', :user => @user_1
          }

          it {
            @book.public_tags.map(&:name).
              should =~ %w(苹果 香蕉 橘子)
          }

          it {
            @book.private_tags(@user_1).map(&:name).
              should =~ %w(芒果 西瓜 猕猴桃)
          }

          it { @book.private_tags(@user_2).should be_blank }

          context '第二个非所有者添加了tag' do
            before {
              @book.set_tag_list '西瓜,草莓,火龙果', :user => @user_2
            }

            it {
              @book.public_tags.map(&:name).
                should =~ %w(苹果 香蕉 西瓜 橘子)
            }

            it {
              @book.private_tags(@user_1).map(&:name).
                should =~ %w(芒果 西瓜 猕猴桃)
            }

            it {
              @book.private_tags(@user_2).map(&:name).
                should =~ %w(火龙果 西瓜 草莓)
            }

            context '第一个非所有者移除了tag' do
              before {
                @book.set_tag_list '橄榄', :user => @user_1
              }

              it {
                @book.public_tags.map(&:name).
                  should =~ %w(苹果 香蕉 橘子)
              }

              it {
                @book.private_tags(@user_1).map(&:name).
                  should =~ %w(橄榄)
              }

              it {
                @book.private_tags(@user_2).map(&:name).
                  should =~ %w(火龙果 西瓜 草莓)
              }
            end
          end
        end
      end

      describe 'set_tag_list(tag_str, :user => user, :force_public => true)' do
        before{
          @book.set_tag_list("java", :user => @user_1, :force_public => true)
        }

        it{
          @book.private_tags(@user_1).map(&:name).should =~ %w(java)
        }

        it{
          @book.public_tags.map(&:name).should =~ %w(java)
        }

        describe '设置 公共 tag' do
          before{
            @book.set_tag_list("编程 api", :user => @creator)
          }

          it{
            @book.private_tags(@creator).map(&:name).should =~ %w(编程 api)
          }

          it{
            @book.public_tags.map(&:name).should =~ %w(java 编程 api)
          }

          describe '再次带 force_public 参数修改 tag' do
            before{
              @book.set_tag_list("编程 学习", :user => @user_1, :force_public => true)
            }

            it{
              @book.private_tags(@user_1).map(&:name).should =~ %w(编程 学习)
            }

            it{
              @book.public_tags.map(&:name).should =~ %w(java 编程 api 学习)
            }

            describe '删除 force_public_tag ' do
              before{
                @book.remove_public_tag('编程 api java')
              }

              it{
                @book.public_tags.map(&:name).should =~ %w(学习)
              }
            end
          end
        end

        describe '带 force_public 参数修改 tag' do
          before{
            @book.set_tag_list("编程 api", :user => @user_1, :force_public => true)
            @book.reload
          }

          it{
            @book.private_tags(@user_1).map(&:name).should =~ %w(编程 api)
          }

          it{
            @book.public_tags.map(&:name).should =~ %w(java 编程 api)
          }

          describe '删除 force_public_tag ' do
            before{
              @book.remove_public_tag('编程 api')
            }

            it{
              @book.public_tags.map(&:name).should =~ %w(java)
            }
          end
        end
      end
    end

    describe '根据TAG查询' do
      before{
        @creator_1 = User.create!(:name => 'creator_1')
        @book_1 = Book.create!(:name => 'book_1', :creator => @creator_1)
        
        @creator_2 = User.create!(:name => 'creator_2')
        @book_2 = Book.create!(:name => 'book_2', :creator => @creator_2)

        @creator_3 = User.create!(:name => 'creator_3')
        @book_3 = Book.create!(:name => 'book_3', :creator => @creator_3)

        @creator_4 = User.create!(:name => 'creator_4')
        @book_4 = Book.create!(:name => 'book_4', :creator => @creator_4)

        @book_1.set_tag_list('java,api')
        @book_4.set_tag_list('java')

        @book_1.set_tag_list('java', :user => @user_1)
        @book_2.set_tag_list('java,api', :user => @user_1)

        @book_2.set_tag_list('java', :user => @user_2)
        @book_3.set_tag_list('java', :user => @user_2)      
      }

      it{
        @book_1.public_tags.map(&:name).should =~ ['java','api']
        @book_1.private_tags(@user_1).map(&:name).should =~ ['java']
        @book_1.private_tags(@user_2).should == []

        @book_2.public_tags.map(&:name).should =~ ['java']
        @book_2.private_tags(@user_1).map(&:name).should =~ ['java','api']
        @book_2.private_tags(@user_2).map(&:name).should =~ ['java']

        @book_3.public_tags.should == []
        @book_3.private_tags(@user_1).should == []
        @book_3.private_tags(@user_2).map(&:name).should =~ ['java']

        @book_4.public_tags.map(&:name).should =~ ['java']
        @book_4.private_tags(@user_1).should == []
        @book_4.private_tags(@user_2).should == []
      }

      it{
        (Book.by_tag('java') - [@book_1, @book_2, @book_4]).should == []
      }

      it{
        (Book.by_tag('java', :user => @user_1) - [@book_1, @book_2, @book_4]).should == []
      }

      it{
        (Book.by_tag('java', :user => @user_2) - [@book_1, @book_2, @book_3, @book_4]).should == []
      }

      it{
        (Book.by_tag('api') - [@book_1]).should == []
      }

      it{
        (Book.by_tag('api', :user => @user_1) - [@book_1,@book_2]).should == []
      }

      it{
        (Book.by_tag('api', :user => @user_2) - [@book_1]).should == []
      }

      context '#private_tagged_count' do
        before{
          @tag_java = MindpinSimpleTags::Tag.by_name('java').first
          @tag_api = MindpinSimpleTags::Tag.by_name('api').first
        }

        it{
          @book_1.private_tagged_count(@tag_java).should == 2
        }

        it{
          @book_1.private_tagged_count(@tag_api).should == 1 
        }

        it{
          @book_2.private_tagged_count(@tag_java).should == 2
        }

        it{
          @book_2.private_tagged_count(@tag_api).should == 1
        }

        it{
          @book_3.private_tagged_count(@tag_java).should == 1
        }

        it{
          @book_3.private_tagged_count(@tag_api).should == 0
        }

        it{
          @book_4.private_tagged_count(@tag_java).should == 1
        }

        it{
          @book_4.private_tagged_count(@tag_api).should == 0
        }
      end

      context 'tagged_with_creator' do
        before{
          @tag_java = MindpinSimpleTags::Tag.by_name('java').first
          @tag_api = MindpinSimpleTags::Tag.by_name('api').first
        }

        it{
          @book_1.tagged_with_creator?(@tag_java).should == true
        }

        it{
          @book_1.tagged_with_creator?(@tag_api).should == true
        }

        it{
          @book_2.tagged_with_creator?(@tag_java).should == false
        }

        it{
          @book_2.tagged_with_creator?(@tag_api).should == false
        }

        it{
          @book_3.tagged_with_creator?(@tag_java).should == false
        }

        it{
          @book_3.tagged_with_creator?(@tag_api).should == false
        }

        it{
          @book_4.tagged_with_creator?(@tag_java).should == true
        }

        it{
          @book_4.tagged_with_creator?(@tag_api).should == false
        }

      end
    end

  end

  describe User do
    before{
      @user = User.create!(:name => 'user_1')
      @user.set_tag_list("编程,java，api 教程")  
    }

    it{
      @user.public_tags.map(&:name).should =~ ['编程','java','api','教程'] 
    }

    it{
      @user.private_tags(@user).map(&:name).should =~ ['编程','java','api','教程'] 
    }
  end

end
