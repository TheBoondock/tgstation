import {
  Box,
  Button,
  LabeledList,
  Modal,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CoreInfo = {
  core_present: BooleanLike;
  internal_energy: number;
  temp: number;
  min_temperature: number;
  max_temperature: number;
  payload: string;
};

function stringtoboolean(boo: string) {
  if (!boo) {
    return false;
  }
  return true;
}

const CoreDisplay = (props) => {
  const { act, data } = useBackend<CoreInfo>();

  return (
    <Section title="Core Status">
      <LabeledList>
        <ProgressBar
          value={data.temp}
          minValue={data.min_temperature}
          maxValue={data.max_temperature}
        />
      </LabeledList>
      <Section title={data.payload || 'Empty'}>
        buttons=
        {
          <Button
            icon={'Kickstart'}
            selected={stringtoboolean(data.payload)}
            onClick={() => act('begin_implosion')}
          >
            {data.active ? 'Online' : 'Offline'}
          </Button>
        }
      </Section>
    </Section>
  );
};

const Unavailable_Core = (props) => {
  return (
    <Modal>
      <Stack fill vertical>
        <Stack.Item textAlign="center">
          <Box style={{ margin: 'auto' }} textAlign="center" width="300px">
            {'No core detected'}
          </Box>
        </Stack.Item>
      </Stack>
    </Modal>
  );
};

export const CoreMonitor = (props) => {
  const { data } = useBackend<CoreInfo>();

  return (
    <Window width={310} height={240}>
      <Window.Content>
        {data.core_present ? <CoreDisplay /> : <Unavailable_Core />}
      </Window.Content>
    </Window>
  );
};
