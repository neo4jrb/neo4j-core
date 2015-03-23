require 'spec_helper'

describe 'label', api: :server do
  it_behaves_like 'Neo4j::Label'

  describe 'index class methods' do
    before(:all) do
      label = Neo4j::Label.create(:foo)
      label.create_index('bar')
    end

    after(:all) do
      label = Neo4j::Label.create(:foo)
      label.drop_index('bar')
    end

    describe 'indexes' do
      it 'lists all known indexes' do
        indexes = Neo4j::Label.indexes
        selected_indexes = indexes.select { |i| i[:property_keys].include?('bar') && i[:label] == 'foo' }
        expect(selected_indexes).not_to be_empty
      end
    end

    describe 'index?' do
      it 'identifies a known index' do
        expect(Neo4j::Label.index?('foo', 'bar')).to be_truthy
      end

      it 'returns false when an index is not defined' do
        expect(Neo4j::Label.index?('bar', 'baz')).to be_falsey
      end
    end
  end

  describe 'constraint class methods' do
    before(:all) do
      label = Neo4j::Label.create(:foo)
      label.drop_index('foo', 'bar')
      label.create_constraint(:bar, type: :unique) unless Neo4j::Label.constraint?(:foo, :bar)
    end

    after(:all) do
      label = Neo4j::Label.create(:foo)
      label.drop_constraint('bar', type: :unique)
    end

    describe 'constraints' do
      it 'lists all known constraints' do
        constraints = Neo4j::Label.constraints
        selected_constraints = constraints.select { |i| i[:property_keys].include?('bar')  && i[:label] == 'foo' }
        expect(selected_constraints).not_to be_empty
      end
    end

    describe 'constraint?' do
      it 'recognizes a known constraint' do
        expect(Neo4j::Label.constraint?(:foo, :bar)).to be_truthy
      end

      it 'returns false when constraint not defined' do
        expect(Neo4j::Label.constraint?(:bar, :foo)).to be_falsey
      end
    end
  end

  describe 'drop_all_indexes' do
    it 'drops all indexes' do
      expect(Neo4j::Session.current).to receive(:_query_or_fail).at_least(1).times.with(/DROP INDEX ON/)
      Neo4j::Label.drop_all_indexes
    end
  end

  describe 'drop_all_constraints' do
    let(:label) { Neo4j::Label.create(:foo) }

    before do
      label.create_constraint(:bar, type: :unique)
    end

    after do
      if Neo4j::Label.index?(:foo, :bar)
        label.drop_constraint('bar', type: :unique)
        begin
          label.drop_index(:bar)
        rescue; end
      end
    end

    it 'drops all constraints' do
      expect(Neo4j::Session.current).to receive(:_query_or_fail).at_least(1).times.with(/DROP CONSTRAINT ON/)
      Neo4j::Label.drop_all_constraints
    end
  end
end
