require 'spec_helper'

describe Neo4j::Transaction do
  describe '.session_and_run_in_tx_from_args' do
    let(:args) { [] }
    let(:current_session) { double('current session') }
    before do
      allow(Neo4j::Session).to receive(:current!).and_return(current_session)
    end
    subject { Neo4j::Transaction.session_and_run_in_tx_from_args(args) }

    it { should eq([current_session, true]) }

    let_context args: [true] { it { should eq([current_session, true]) } }
    let_context args: [false] { it { should eq([current_session, false]) } }
    let_context args: [:session] { it { should eq([:session, true]) } }

    # This method doesn't care what you pass as the non-boolean value
    # so using a symbol here
    let_context args: [:session] { it { should eq([:session, true]) } }


    let_context args: [false, :session] { it { should eq([:session, false]) } }
    let_context args: [true, :session] { it { should eq([:session, true]) } }

    let_context args: [:session, false] { it { should eq([:session, false]) } }
    let_context args: [:session, true] { it { should eq([:session, true]) } }

    let_context args: [:session, true, :foo] do
      it { expect { subject }.to raise_error ArgumentError, /Too many arguments/ }
    end
  end
end
