/*
||
|| @file FiniteStateMachine.h
|| @version 1.2
|| @author Alexander Brevig
|| @contact alexanderbrevig@gmail.com
||
|| @description
|| | Provide an easy way of making finite state machines
|| #
||
|| @license
|| | This library is free software; you can redistribute it and/or
|| | modify it under the terms of the GNU Lesser General Public
|| | License as published by the Free Software Foundation; version
|| | 2.1 of the License.
|| |
|| | This library is distributed in the hope that it will be useful,
|| | but WITHOUT ANY WARRANTY; without even the implied warranty of
|| | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
|| | Lesser General Public License for more details.
|| |
|| | You should have received a copy of the GNU Lesser General Public
|| | License along with this library; if not, write to the Free Software
|| | Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
|| #
||
*/

#ifndef FINITESTATEMACHINE_H
#define FINITESTATEMACHINE_H

#include <WProgram.h>

#define NO_ENTER (0)
#define NO_UPDATE (0)
#define NO_EXIT (0)

#define FSM FiniteStateMachine

//define the functionality of the states
class State {
	public:
		State( void (*updateFunction)() );
		State( void (*enterFunction)(), void (*updateFunction)(), void (*exitFunction)() );
		//State( byte newId, void (*enterFunction)(), void (*updateFunction)(), void (*exitFunction)() );
		
		//void getId();
		void enter();
		void update();
		void exit();
	private:
		//byte id;
		void (*userEnter)();
		void (*userUpdate)();
		void (*userExit)();
};

//define the finite state machine functionality
class FiniteStateMachine {
	public:
		FiniteStateMachine(State& current);
		
		FiniteStateMachine& update();
		FiniteStateMachine& transitionTo(State& state);
		FiniteStateMachine& immediateTransitionTo(State& state);
        bool isInState(State& state); //Added by Henry Herman 10-30-09
		//State* getCurrentState();
	private:
		State* currentState;
		State* nextState;
};

#endif

/*
|| @changelog
|| | 1.2 2009-05-18 - Alexander Brevig : enter and exit bug fix
|| | 1.1 2009-05-18 - Alexander Brevig : Added support for cascaded calls
|| | 1.0 2009-04-13 - Alexander Brevig : Initial Release
|| #
*/