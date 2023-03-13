import { Section, Table } from '../components';
import { NtosWindow } from '../layouts';
import { useBackend } from '../backend';
import { map } from 'common/collections';

export const SocialRating = (prop, context) => {
  const { act, data } = useBackend(context);
  const { Crewlist = {} } = data;
  const modified = map((name, number) => (
    <Table.Row key={name}>
      <Table.Cell key={name}>
        {name} {number}
      </Table.Cell>
    </Table.Row>
  ));
  return (
    <NtosWindow width={600} height={500}>
      <NtosWindow.Content scrollable>
        <Section title="Crew Ratings" />
        {modified}
      </NtosWindow.Content>
    </NtosWindow>
  );
};
